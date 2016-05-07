require 'session_keys/version'
require 'rbnacl/libsodium'
require 'rbnacl'
require 'zxcvbn'
require 'base64'

# SessionKeys deterministic cryptographic key generation.
module SessionKeys
  # Opslimit represents a maximum amount of computations to perform.
  # Raising this number will make the function require more CPU cycles to
  # compute a key.
  #
  # Number of scrypt computations for scrypt to perform for interactive security setting.
  # Set to SCRYPT_MEMLIMIT_INTERACTIVE / 32
  #
  # For interactive, online operations, `SCRYPT_OPSLIMIT_INTERACTIVE` and
  # `SCRYPT_MEMLIMIT_INTERACTIVE` provide a safe base line for these two parameters.
  # However, using higher values may improve security.
  #
  # See : https://download.libsodium.org/doc/password_hashing/scrypt.html
  SCRYPT_OPSLIMIT_INTERACTIVE = 2**19

  # Memlimit is the maximum amount of RAM that the function will use, in
  # bytes. It is highly recommended to allow the function to use at least 16
  # megabytes.
  #
  # Max RAM in Bytes to be used by scrypt for interactive security setting.
  SCRYPT_MEMLIMIT_INTERACTIVE = 2**24

  # Number of scrypt computations for scrypt to perform for sensitive security setting.
  # Set to SCRYPT_MEMLIMIT_SENSITIVE / 32
  #
  # For highly sensitive data, `SCRYPT_OPSLIMIT_SENSITIVE` and `SCRYPT_MEMLIMIT_SENSITIVE` can
  # be used as an alternative. But with these parameters, deriving a key takes
  # about 2 seconds on a 2.8 Ghz Core i7 CPU and requires up to 1 gigabyte of
  # dedicated RAM.
  SCRYPT_OPSLIMIT_SENSITIVE = 2**25

  # Max RAM in Bytes to be used by scrypt for sensitive security setting.
  SCRYPT_MEMLIMIT_SENSITIVE = 2**30

  # Size in Bytes of the scrypt derived output for the id
  SCRYPT_DIGEST_SIZE_ID = 32

  # Size in Bytes of the scrypt derived output for the password
  SCRYPT_DIGEST_SIZE_PASSWORD = 256

  # A site-wide 32 Byte common random value that will be concatenated with a value
  # being hashed for some additional measure of security against dictionary
  # style attacks. This value was randomly chosen but must be the same across
  # implementations and is assumed public.
  PEPPER = 'f01f0a0c44a2d1e7e5b00d7dc78941d404474a90ce7f4ae9d1432bf76fa169e7'.freeze

  # Deterministically generates a collection of derived encryption key material from
  # a provided id and password. Uses SHA256 and scrypt for key derivation.
  #
  # @param id [String] a unique US-ASCII or UTF-8 encoded String identifier such as a username or
  #   email address. Max length 256 characters.
  # @param password [String] a cryptographically strong US-ASCII or UTF-8 encoded password or
  #   passphrase. Max length 256 characters.
  # @param strength [Symbol] the desired strength of the key derivation. Can be
  #   the symbols :interactive or (:sensitive).
  # @param min_password_entropy [Integer] the minimum (75) estimated entropy allowed
  #   for the password. This will be measured with Zxcvbn.
  # @return [Hash] returns a Hash of keys and derived key material.
  # @raise [ArgumentError] if invalid arguments are provided.
  def self.generate(id, password, strength = :sensitive, min_password_entropy = 75)
    unless id.is_a?(String) && ['US-ASCII', 'UTF-8'].include?(id.encoding.name)
      raise ArgumentError, 'invalid id, not a US-ASCII or UTF-8 string'
    end

    unless id.length.between?(1,256)
      raise ArgumentError, 'invalid id, must be between 1 and 256 characters in length'
    end

    unless password.is_a?(String) && ['US-ASCII', 'UTF-8'].include?(password.encoding.name)
      raise ArgumentError, 'invalid password, not a US-ASCII or UTF-8 string'
    end

    # Enforce max length only due to Zxcvbn taking a *long* time to
    # process long strings and determine entropy.
    unless password.length.between?(1,256)
      raise ArgumentError, 'invalid password, must be between 1 and 256 characters in length'
    end

    unless min_password_entropy.is_a?(Integer) && min_password_entropy.between?(1, 512)
      raise ArgumentError, 'invalid min_password_entropy, must be an Integer between 1 and 512'
    end

    password_test = Zxcvbn.test(password)
    unless password_test.entropy.round >= min_password_entropy
      raise ArgumentError, "invalid password, must be at least #{min_password_entropy} bits of estimated entropy"
    end

    unless [:interactive, :sensitive].include?(strength)
      raise ArgumentError, 'invalid strength, must be :interactive (min), or :sensitive (strong)'
    end

    start_processing_time = Time.now

    # Run the ID and a 'pepper' (an app common salt) through scrypt. This will be
    # the system ID for this user. This processing is done to prevent knowledge
    # of the user on the server side and prevent the ability to reverse this
    # ID back into a username or email. Using scrypt instead of a SHA256 Hash
    # is so that it will also take unreasonable effort for someone with a list
    # of user identifiers from looking up users on the system quickly even if
    # provided with a local copy of the DB.
    id_sha256_bytes = RbNaCl::Hash.sha256(id.bytes.pack('C*'))
    id_sha256_pepper_bytes = RbNaCl::Hash.sha256("#{id}#{id.length}#{PEPPER}#{PEPPER.length}".bytes.pack('C*'))

    id_scrypt_hex = RbNaCl::PasswordHash.scrypt(
      id_sha256_bytes,
      id_sha256_pepper_bytes,
      SCRYPT_OPSLIMIT_INTERACTIVE,
      SCRYPT_MEMLIMIT_INTERACTIVE,
      SCRYPT_DIGEST_SIZE_ID
    ).bytes.map { |byte| '%02x' % byte }.join

    # libsodium : By design, a password whose length is 65 bytes or more is
    # reduced to SHA-256(password). This can have security implications if the
    # password is present in another password database using raw, unsalted
    # SHA-256. Or when upgrading passwords previously hashed with unsalted
    # SHA-256 to scrypt. If this is a concern, passwords should be pre-hashed
    # before being hashed using scrypt.
    password_sha256_bytes = RbNaCl::Hash.sha256(password.bytes.pack('C*'))
    password_sha256_pepper_bytes = RbNaCl::Hash.sha256("#{id_scrypt_hex}#{id_scrypt_hex.length}#{PEPPER}#{PEPPER.length}".bytes.pack('C*'))

    # Derive SCRYPT_DIGEST_SIZE_PASSWORD secret bytes. They will be split
    # into 32 Byte chunks to serve as deterministic seeds for ID or key
    # generation. Some derived bytes are reserved for future use.
    password_digest = RbNaCl::PasswordHash.scrypt(
      password_sha256_bytes,
      password_sha256_pepper_bytes,
      strength == :interactive ? SCRYPT_OPSLIMIT_INTERACTIVE : SCRYPT_OPSLIMIT_SENSITIVE,
      strength == :interactive ? SCRYPT_MEMLIMIT_INTERACTIVE : SCRYPT_MEMLIMIT_SENSITIVE,
      SCRYPT_DIGEST_SIZE_PASSWORD
    ).bytes

    # Break up the scrypt digest into 32 Byte seeds.
    secret_bytes = []
    (SCRYPT_DIGEST_SIZE_PASSWORD/32).times { secret_bytes << password_digest.shift(32) }

    # Seed 0 : RbNaCl::SimpleBox
    # The seed bytes are used as a 32 Byte key suitable for
    # simple symetric key encryption using `RbNaCl::SimpleBox`. SimpleBox is
    # a wrapper around NaCl SecretBox construct with automated nonce management.
    #
    # To encrypt/decreypt with this object try:
    #  ciphertext = nacl_simple_box.encrypt('foobar')
    #  plaintext = nacl_simple_box.decrypt(ciphertext)
    nacl_simple_box_key = secret_bytes[0].pack('C*').force_encoding('ASCII-8BIT')
    nacl_simple_box = RbNaCl::SimpleBox.from_secret_key(nacl_simple_box_key)

    # Seed 1 : NaCl Box Keypair
    nacl_enc_sec_seed = secret_bytes[1].pack('C*').force_encoding('ASCII-8BIT')
    nacl_enc_sec_key = RbNaCl::PrivateKey.new(nacl_enc_sec_seed)
    nacl_enc_pub_key = nacl_enc_sec_key.public_key

    # Seed 2 : NaCl Signing Keypair
    nacl_sig_sec_seed = secret_bytes[2].pack('C*').force_encoding('ASCII-8BIT')
    nacl_sig_sec_key = RbNaCl::SigningKey.new(nacl_sig_sec_seed)
    nacl_sig_pub_key = nacl_sig_sec_key.verify_key

    # Seed 3 : Reserved for future use.
    # Seed 4 : Reserved for future use.
    # Seed 5 : Reserved for future use.
    # Seed 6 : Reserved for future use.
    # Seed 7 : Reserved for future use.

    {
      id: id_scrypt_hex,
      nacl_simple_box: nacl_simple_box,
      nacl_enc_pub_key: nacl_enc_pub_key,
      nacl_enc_sec_key: nacl_enc_sec_key,
      nacl_sig_pub_key: nacl_sig_pub_key,
      nacl_sig_sec_key: nacl_sig_sec_key,
      nacl_enc_pub_key_b64: Base64.strict_encode64(nacl_enc_pub_key.to_bytes),
      nacl_sig_pub_key_b64: Base64.strict_encode64(nacl_sig_pub_key.to_bytes),
      process_time: ((Time.now - start_processing_time)*1000).round(2)
    }
  end
end
