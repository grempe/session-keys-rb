require 'test_helper'

describe SessionKeys do
  describe 'constants' do
    it 'should be set to pre-determined interoperable values' do
      SessionKeys::SCRYPT_OPSLIMIT_INTERACTIVE.must_equal 2**19
      SessionKeys::SCRYPT_MEMLIMIT_INTERACTIVE.must_equal 2**24
      SessionKeys::SCRYPT_OPSLIMIT_SENSITIVE.must_equal 2**25
      SessionKeys::SCRYPT_MEMLIMIT_SENSITIVE.must_equal 2**30
      SessionKeys::SCRYPT_DIGEST_SIZE_ID.must_equal 32
      SessionKeys::SCRYPT_DIGEST_SIZE_PASSWORD.must_equal 256
      SessionKeys::PEPPER.must_equal 'f01f0a0c44a2d1e7e5b00d7dc78941d404474a90ce7f4ae9d1432bf76fa169e7'
    end
  end

  describe 'id argument' do
    it 'must accept a min length 1 string' do
      keys = SessionKeys.generate('a', 'my secret password', :interactive, 1)
      keys[:id].length.must_equal 64
    end

    it 'must accept a max length string' do
      keys = SessionKeys.generate('a'*256, 'my secret password', :interactive, 1)
      keys[:id].length.must_equal 64
    end

    it 'must raise an ArgumentError if an invalid ID type was provided' do
      err = ->{ SessionKeys.generate(nil, 'my', :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, not a US-ASCII or UTF-8 string/)
      err = ->{ SessionKeys.generate('a'.force_encoding('BINARY'), 'my', :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, not a US-ASCII or UTF-8 string/)
    end

    it 'must raise an ArgumentError if an invalid ID length was provided' do
      err = ->{ SessionKeys.generate('', 'my', :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, must be between 1 and 256 characters in length/)
      err = ->{ SessionKeys.generate('a'*257, 'my', :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid id, must be between 1 and 256 characters in length/)
    end
  end

  describe 'password argument' do
    it 'must accept a min length 1 string as long as entropy is sufficient' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 1}) do
        keys = SessionKeys.generate('a', 'a', :interactive, 1)
        keys.must_be_instance_of Hash
      end
    end

    it 'must accept a max length 256 string' do
      keys = SessionKeys.generate('a', SecureRandom.hex(128).force_encoding('UTF-8'), :interactive, 512)
      keys.must_be_instance_of Hash
    end

    it 'must raise an ArgumentError if an invalid password type was provided' do
      err = ->{ SessionKeys.generate('someId', nil, :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, not a US-ASCII or UTF-8 string/)
      err = ->{ SessionKeys.generate('someId', 'bin'.force_encoding('BINARY'), :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, not a US-ASCII or UTF-8 string/)
    end

    it 'must raise an ArgumentError if an invalid password length was provided' do
      err = ->{ SessionKeys.generate('someId', '', :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, must be between 1 and 256 characters in length/)
      err = ->{ SessionKeys.generate('someId', 'a'*257, :interactive, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid password, must be between 1 and 256 characters in length/)
    end

    it 'must raise an ArgumentError if measured password entropy is below default minimum' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 74}) do
        err = ->{ SessionKeys.generate('someId', 'a', :interactive) }.must_raise ArgumentError
        err.message.must_match(/invalid password, must be at least 75 bits of estimated entropy/)
      end
    end

    it 'must raise an ArgumentError if measured password entropy is below set minimum' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 9}) do
        err = ->{ SessionKeys.generate('someId', 'a', :interactive, 10) }.must_raise ArgumentError
        err.message.must_match(/invalid password, must be at least 10 bits of estimated entropy/)
      end
    end
  end

  describe 'strength argument' do
    it 'must raise an ArgumentError if an invalid strength was provided' do
      err = ->{ SessionKeys.generate('someId', 'somePass', nil, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid strength, must be :interactive/)
      err = ->{ SessionKeys.generate('someId', 'somePass', 'sensitive', 1) }.must_raise ArgumentError
      err.message.must_match(/invalid strength, must be :interactive/)
      err = ->{ SessionKeys.generate('someId', 'somePass', :other_symbol, 1) }.must_raise ArgumentError
      err.message.must_match(/invalid strength, must be :interactive/)
    end
  end

  describe 'min_password_entropy argument' do
    it 'must accept minimum value of 1' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 1}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 1)
        keys.must_be_instance_of Hash
      end
    end

    it 'must accept password with default value of 75' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 75}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive)
        keys.must_be_instance_of Hash
      end
    end

    it 'must round the measured entropy to the nearest Integer' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 75.1}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 75)
        keys.must_be_instance_of Hash
      end
    end

    it 'must accept maximum value of 512' do
      Zxcvbn.stub :test, OpenStruct.new({entropy: 512}) do
        keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 512)
        keys.must_be_instance_of Hash
      end
    end

    it 'must raise an ArgumentError if out of bounds' do
      err = ->{ SessionKeys.generate('someId', 'somePass', :interactive, nil) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', :interactive, -1) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', :interactive, 0) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', :interactive, '2') }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
      err = ->{ SessionKeys.generate('someId', 'somePass', :interactive, 513) }.must_raise ArgumentError
      err.message.must_match(/invalid min_password_entropy/)
    end
  end

  describe 'generate' do
    it 'must return the correct response hash' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 2)
      keys.keys.must_equal [:id, :nacl_simple_box, :nacl_enc_pub_key,
        :nacl_enc_sec_key, :nacl_sig_pub_key, :nacl_sig_sec_key,
        :nacl_enc_pub_key_b64, :nacl_sig_pub_key_b64, :process_time]
    end

    it 'must return id' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 2)
      keys.key?(:id).must_equal true
      keys[:id].must_be_instance_of String
      keys[:id].length.must_equal 64
    end

    it 'must return a nacl_simple_box of the right type' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 2)
      keys.key?(:nacl_simple_box).must_equal true
      keys[:nacl_simple_box].must_be_instance_of RbNaCl::SimpleBox
    end

    it 'must return NaCl encryption keypairs of the right type' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 2)
      keys[:nacl_enc_sec_key].must_be_instance_of RbNaCl::Boxes::Curve25519XSalsa20Poly1305::PrivateKey
      keys[:nacl_enc_pub_key].must_be_instance_of RbNaCl::Boxes::Curve25519XSalsa20Poly1305::PublicKey
    end

    it 'must return NaCl signing keypairs of the right type' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 2)
      keys[:nacl_sig_sec_key].must_be_instance_of RbNaCl::Signatures::Ed25519::SigningKey
      keys[:nacl_sig_pub_key].must_be_instance_of RbNaCl::Signatures::Ed25519::VerifyKey
    end

    it 'must return process_time of the right type and range' do
      keys = SessionKeys.generate('user@example.com', 'my secret password', :interactive, 2)
      keys[:process_time].must_be_instance_of Float
      keys[:process_time].must_be :>, 10.0
      keys[:process_time].must_be :<, 100.0
    end
  end
end
