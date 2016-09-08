require_relative 'test_helper'

describe SessionKeys do
  describe 'constants' do
    it 'should be set to pre-determined interoperable values' do
      SessionKeys::SCRYPT_DIGEST_SIZE.must_equal 256
    end
  end

  describe 'id argument' do
    it 'must accept a min length 1 string' do
      keys = SessionKeys.generate('a', 'my secret password', 1)
      keys[:id].length.must_equal 64
    end

    it 'must accept a max length string' do
      keys = SessionKeys.generate('a'*256, 'my secret password', 1)
      keys[:id].length.must_equal 64
    end

    it 'must raise an ArgumentError if an invalid ID type was provided' do
      err = ->{ SessionKeys.generate(nil, 'my', 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, not a US-ASCII or UTF-8 string/)
      err = ->{ SessionKeys.generate('a'.force_encoding('BINARY'), 'my', 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, not a US-ASCII or UTF-8 string/)
    end

    it 'must raise an ArgumentError if an invalid ID length was provided' do
      err = ->{ SessionKeys.generate('', 'my', 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, must be between 1 and 256 characters in length/)
      err = ->{ SessionKeys.generate('a'*257, 'my', 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, must be between 1 and 256 characters in length/)
    end
  end

  describe 'password argument' do
    it 'must accept a min length 1 string as long as entropy is sufficient' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 1}) do
        keys = SessionKeys.generate('a', 'a', 1)
        keys.must_be_instance_of Hash
      end
    end

    it 'must accept a max length 256 string' do
      keys = SessionKeys.generate('a', SecureRandom.hex(128).force_encoding('UTF-8'), 512)
      keys.must_be_instance_of Hash
    end

    it 'must raise an ArgumentError if an invalid password type was provided' do
      err = ->{ SessionKeys.generate('someId', nil, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, not a US-ASCII or UTF-8 string/)
      err = ->{ SessionKeys.generate('someId', 'bin'.force_encoding('BINARY'), 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, not a US-ASCII or UTF-8 string/)
    end

    it 'must raise an ArgumentError if an invalid password length was provided' do
      err = ->{ SessionKeys.generate('someId', '', 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, must be between 1 and 256 characters in length/)
      err = ->{ SessionKeys.generate('someId', 'a'*257, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, must be between 1 and 256 characters in length/)
    end

    it 'must raise an ArgumentError if measured password entropy is below default minimum' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 74}) do
        err = ->{ SessionKeys.generate('someId', 'a') }.must_raise ArgumentError
        err.message.must_match(/invalid password, must be at least 75 bits of estimated entropy/)
      end
    end

    it 'must raise an ArgumentError if measured password entropy is below set minimum' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 9}) do
        err = ->{ SessionKeys.generate('someId', 'a', 10) }.must_raise ArgumentError
        err.message.must_match(/invalid password, must be at least 10 bits of estimated entropy/)
      end
    end
  end

  describe 'min_password_entropy argument' do
    it 'must accept minimum value of 1' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 1}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password', 1)
        keys.must_be_instance_of Hash
      end
    end

    it 'must accept password with default value of 75' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 75}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password')
        keys.must_be_instance_of Hash
      end
    end

    it 'must round the measured entropy to the nearest Integer' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 75.1}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password', 75)
        keys.must_be_instance_of Hash
      end
    end

    it 'must accept maximum value of 512' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 512}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password', 512)
        keys.must_be_instance_of Hash
      end
    end

    it 'must raise an ArgumentError if out of bounds' do
      err = ->{ SessionKeys.generate('someId', 'somePass', nil) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', -1) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', 0) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', '2') }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', 513) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
    end
  end

  describe 'generate' do
    it 'must return the correct response hash' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', 2)
      keys.keys.must_equal [:id, :byte_keys, :hex_keys, :nacl_encryption_key_pairs,
        :nacl_encryption_key_pairs_base64, :nacl_signing_key_pairs,
        :nacl_signing_key_pairs_base64, :process_time]
    end

    it 'must return id' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', 2)
      keys.key?(:id).must_equal true
      keys[:id].must_be_instance_of String
      keys[:id].length.must_equal 64
    end

    it 'must return process_time of the right type and range' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', 2)
      keys[:process_time].must_be_instance_of Float
      keys[:process_time].must_be :>, 10.0
      keys[:process_time].must_be :<, 100.0
    end
  end

  describe 'encrypt and decrypt' do
    it 'must work using generated encryption keys' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', 2)

      # Assign the first of 8 keypairs to Alice for this test
      alice = keys[:nacl_encryption_key_pairs][0]

      # Bob gets the second set for this test
      bob = keys[:nacl_encryption_key_pairs][1]

      # The message Alice wants to send
      plaintext = 'foo bar baz'

      # Encrypt message from Alice to Bob
      a_box = RbNaCl::Box.new(bob[:public_key], alice[:secret_key])
      nonce = RbNaCl::Random.random_bytes(a_box.nonce_bytes)
      ciphertext = a_box.encrypt(nonce, plaintext)

      # Decryption of Alice's message by Bob
      # The nonce would be shared along with the ciphertext
      b_box = RbNaCl::Box.new(alice[:public_key], bob[:secret_key])
      decrypted_plaintext = b_box.open(nonce, ciphertext)

      decrypted_plaintext.must_equal plaintext
    end

    it 'can decrypt a message with RbNaCl encrypted by TweetNaCl.js client' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', 2)

      alice = keys[:nacl_encryption_key_pairs][0]

      # Enter as the 'Their Public Key' value on website
      # alice[:public_key] = ONIMmjAJRAqO9iix85QojI03LCSC1O7miYSJA/23mlQ=
      alice_b64 = keys[:nacl_encryption_key_pairs_base64][0]

      # Created with : https://tweetnacl.js.org/#/sign
      nonce_b64 = 'KQIsPlYgOKGurOf1DuqlUTr4K8zr2M86'
      bob_secret_key_b64 = 'cds1gX0u9kTC76utKilzAk3kuKUTGwdUP0QmbHw4kCE='
      bob_public_key_b64 = 'LpwXfjbYZsReIKozHivmBPu8kPUEe7sXRjVQjhSD9nI='
      message = 'tweet-nacl-js'
      box_b64 = 'O/N+xSI/o9QSoS1V/9MPB78epwEvEiP79DdeUdQ='

      box = RbNaCl::Box.new(Base64.decode64(bob_public_key_b64), alice[:secret_key])
      decrypted_message = box.open(Base64.decode64(nonce_b64), Base64.decode64(box_b64))

      decrypted_message.must_equal message
    end
  end

  describe 'sign and verify' do
    it 'must work using generated signing keys' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', 2)

      # Assign the first of 8 keypairs to Alice for this test
      alice = keys[:nacl_signing_key_pairs][0]

      # The message Alice wants to sign
      message = 'foo bar baz'

      signature = alice[:secret_key].sign(message)

      # Obtain the verify key for a given signing key
      verify_key = alice[:public_key]

      # Convert the verify key to a string to send it to a third party
      verify_key_s = verify_key.to_s

      # verify that the Base64 version this lib generates matches the Base64 encoded string output from RbNaCl
      # Base64.strict_encode64 is used which does not add a newline
      keys[:nacl_signing_key_pairs_base64][0][:public_key].must_equal Base64.strict_encode64(verify_key_s)

      # SEND MESSAGE + SIGNATURE TO BOB

      # Create a new verification key from the string
      verify_key = RbNaCl::VerifyKey.new(verify_key_s)

      # Check the validity of a message's signature
      # Will raise RbNaCl::BadSignatureError if the signature check fails
      verify_key.verify(signature, message).must_equal true
    end

    it 'can verify a message with RbNaCl signed by TweetNaCl.js client' do
      # Created with : https://tweetnacl.js.org/#/sign
      # secret key : nmZUa3RhbPJA8rJHj8B1UWtQp0ihM4mTE4M5XxGy/PE4ckiAHFabShY+Nfl01NGr5SxHplO5DRJo5hni/ynSBw==
      # public key : OHJIgBxWm0oWPjX5dNTRq+UsR6ZTuQ0SaOYZ4v8p0gc=
      # message : 'tweet-nacl-js'

      # generated signature
      verify_key_s = 'OHJIgBxWm0oWPjX5dNTRq+UsR6ZTuQ0SaOYZ4v8p0gc='

      # recipient verification
      verify_key = RbNaCl::VerifyKey.new(Base64.decode64(verify_key_s))
      verify_key.verify(Base64.decode64('SClbozQrNzjxS4rLZbFNYB1cu/EMosoOqZVlymLJ4o+ptjbeOSW+JS+vheJ5fQbcQm21jqRozfWBKkp7kePeBw=='), 'tweet-nacl-js').must_equal true
    end
  end

end
