require 'session_keys/version'
require 'rbnacl/libsodium'
require 'rbnacl'
require 'zxcvbn'
require 'base64'

# SessionKeys deterministic cryptographic key generation.
module SessionKeys
  # Size in bytes of the scrypt derived output
  SCRYPT_DIGEST_SIZE = 256

  # Deterministically generates a collection of derived encryption key material from
  # a provided id and password/passphrase. Uses SHA256 and scrypt for key derivation.
  #
  # @param id [String] a unique US-ASCII or UTF-8 encoded String identifier such as a username or
  #   email address. Max length 256 characters.
  # @param password [String] a cryptographically strong US-ASCII or UTF-8 encoded password or
  #   passphrase. Max length 256 characters.
  # @param min_password_entropy [Integer] the minimum (75) estimated entropy allowed
  #   for the password. This will be measured with Zxcvbn.
  # @return [Hash] returns a Hash of keys and derived key material.
  # @raise [ArgumentError] if invalid arguments are provided.
  def self.generate(id, password, min_password_entropy = 75)
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

    start_processing_time = Time.now

    id_sha256_bytes = RbNaCl::Hash.sha256(id.bytes.pack('C*'))
    id_sha256_hex = id_sha256_bytes.bytes.map { |byte| '%02x' % byte }.join

    # libsodium : By design, a password whose length is 65 bytes or more is
    # reduced to SHA-256(password). This can have security implications if the
    # password is present in another password database using raw, unsalted
    # SHA-256. Or when upgrading passwords previously hashed with unsalted
    # SHA-256 to scrypt. If this is a concern, passwords should be pre-hashed
    # before being hashed using scrypt.
    scrypt_key = RbNaCl::Hash.sha256(password.bytes.pack('C*'))

    # Tie the sycrypt password bytes to the ID they are associate with by
    # utilizing the ID as the salt. Include the ID length and an additional
    # string to harden the salt.
    scrypt_salt = RbNaCl::Hash.sha256([id_sha256_hex,
                                       id_sha256_hex.length,
                                       'session_keys'].join('').bytes.pack('C*'))

    # Derive SCRYPT_DIGEST_SIZE secret bytes
    password_digest = RbNaCl::PasswordHash.scrypt(
      scrypt_key,
      scrypt_salt,
      16384 * 32,
      16384 * 32 * 32,
      SCRYPT_DIGEST_SIZE
    ).bytes

    num_keys = SCRYPT_DIGEST_SIZE / 32

    byte_keys = []
    num_keys.times { byte_keys << password_digest.shift(32) }

    hex_keys = byte_keys.map { |key|
      key.map { |byte| '%02x' % byte }.join
    }

    nacl_encryption_key_pairs = byte_keys.map { |key|
      seed = key.pack('C*').force_encoding('ASCII-8BIT')
      sec_key = RbNaCl::PrivateKey.new(seed)
      pub_key = sec_key.public_key
      {secret_key: sec_key, public_key: pub_key}
    }

    nacl_encryption_key_pairs_base64 = nacl_encryption_key_pairs.map { |keypair|
      pub_key = Base64.strict_encode64(keypair[:public_key].to_bytes)
      sec_key = Base64.strict_encode64(keypair[:secret_key].to_bytes)
      {secret_key: sec_key, public_key: pub_key}
    }

    nacl_signing_key_pairs = byte_keys.map { |key|
      seed = key.pack('C*').force_encoding('ASCII-8BIT')
      sec_key = RbNaCl::SigningKey.new(seed)
      pub_key = sec_key.verify_key
      {secret_key: sec_key, public_key: pub_key}
    }

    nacl_signing_key_pairs_base64 = nacl_signing_key_pairs.map { |keypair|
      pub_key = Base64.strict_encode64(keypair[:public_key].to_bytes)
      sec_key = Base64.strict_encode64(keypair[:secret_key].to_bytes)
      {secret_key: sec_key, public_key: pub_key}
    }

    {
      id: id_sha256_hex,
      byte_keys: byte_keys,
      hex_keys: hex_keys,
      nacl_encryption_key_pairs: nacl_encryption_key_pairs,
      nacl_encryption_key_pairs_base64: nacl_encryption_key_pairs_base64,
      nacl_signing_key_pairs: nacl_signing_key_pairs,
      nacl_signing_key_pairs_base64: nacl_signing_key_pairs_base64,
      process_time: ((Time.now - start_processing_time)*1000).round(2)
    }
  end
end
