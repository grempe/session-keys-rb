require 'test_helper'

describe SessionKeys do

  ##########################################################################
  # WARNING : WARNING : WARNING : WARNING : WARNING : WARNING : WARNING
  # DO NOT CHANGE THE RESULT VALUES. THEY ARE USED BY MORE THAN ONE LIBRARY
  # AND THE OUTPUTS MUST BE CONSTANT TO ENSURE INTEROPERABILITY!
  #
  # IF THESE TESTS NO LONGER PASS THEN INTEROPERABILITY IS BROKEN!
  ##########################################################################

  describe 'interop test' do
    it 'must create the expected output for :interactive strength' do
      keys = SessionKeys.generate('user@example.com', 'sky bulge stance neal barley host spec', :interactive)

      # ID
      keys[:id].must_equal 'f8ace21f75792cf9b73e0211b4f0cf4a0a131cfb7c30f8ae37c1fa7d42f67b16'

      # NaCl Encryption Keypair
      Base64.strict_encode64(keys[:nacl_enc_sec_key].to_bytes).must_equal 'K+j5qY63wBOkkj/08Ok9HukLa3lia4IK1O1WlyaUhqk='
      Base64.strict_encode64(keys[:nacl_enc_pub_key].to_bytes).must_equal 'aLK6+47RN0iYw8jzooZLGCPLkv2V3RJJHs//AqfyRjY='
      keys[:nacl_enc_pub_key_b64].must_equal Base64.strict_encode64(keys[:nacl_enc_pub_key].to_bytes)

      # NaCl Signing Keypair
      Base64.strict_encode64(keys[:nacl_sig_sec_key].keypair_bytes).must_equal 'DRD2PGZtyRcn1WKDBz8X+gCiaITHjOkHKVb1PeEB7hzWFJJwWm7RnZmduC9eSwwiT0j/dM3pVJKs6P5zyl9sBQ=='
      Base64.strict_encode64(keys[:nacl_sig_pub_key].to_bytes).must_equal '1hSScFpu0Z2ZnbgvXksMIk9I/3TN6VSSrOj+c8pfbAU='
      keys[:nacl_sig_pub_key_b64].must_equal Base64.strict_encode64(keys[:nacl_sig_pub_key].to_bytes)
    end

    it 'must create the expected output for :sensitive strength' do
      keys = SessionKeys.generate('user@example.com', 'curio beef devon fit fugue need frilly', :sensitive)

      # ID
      keys[:id].must_equal 'f8ace21f75792cf9b73e0211b4f0cf4a0a131cfb7c30f8ae37c1fa7d42f67b16'

      # NaCl Encryption Keypair
      Base64.strict_encode64(keys[:nacl_enc_sec_key].to_bytes).must_equal 'yg+1lKtog0W6rYdfToiOB4t24uFO1KIjJUsYrgMa+qg='
      Base64.strict_encode64(keys[:nacl_enc_pub_key].to_bytes).must_equal '/WYkP2xmp6o23gmdP8lIeQ6gdhGLAEjModprDkFCd1M='
      keys[:nacl_enc_pub_key_b64].must_equal Base64.strict_encode64(keys[:nacl_enc_pub_key].to_bytes)

      # NaCl Signing Keypair
      Base64.strict_encode64(keys[:nacl_sig_sec_key].keypair_bytes).must_equal 'dJpE0Kfj+1CVlYdR4vc4IH15l3vbve3QAMQ2SHZ7TTyagntbIHQ9W2XjRzcYetkWkQv5nZWZDDO4mZ3a/FgTUg=='
      Base64.strict_encode64(keys[:nacl_sig_pub_key].to_bytes).must_equal 'moJ7WyB0PVtl40c3GHrZFpEL+Z2VmQwzuJmd2vxYE1I='
      keys[:nacl_sig_pub_key_b64].must_equal Base64.strict_encode64(keys[:nacl_sig_pub_key].to_bytes)
    end
  end
end
