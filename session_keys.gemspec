# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'session_keys/version'

Gem::Specification.new do |spec|
  spec.name          = 'session_keys'
  spec.version       = SessionKeys::VERSION
  spec.authors       = ['Glenn Rempe']
  spec.email         = ['glenn@rempe.us']

  spec.required_ruby_version = '>= 2.1.0'

  cert = File.expand_path('~/.gem-certs/gem-private_key_grempe.pem')
  if cert && File.exist?(cert)
    spec.signing_key = cert
    spec.cert_chain = ['certs/gem-public_cert_grempe.pem']
  end

  spec.summary = <<-EOF
    SessionKeys generates deterministic user IDs and NaCl encryption/signing
    keypairs from an identifier, such as a username or email address, a
    password, and a strength value.
  EOF

  spec.description = <<-EOF
    SessionKeys is a cryptographic tool for the deterministic generation of
    NaCl compatible Curve25519 encryption and Ed25519 digital signature keys.

    The strength of the system is rooted in the fact that the keypairs are derived from
    passing an identifier, such as a username or email address, and a high-entropy
    passphrase through the SHA256 one-way hash and the scrypt key derivation
    functions. This means that no private key material need ever be writter to
    disk or transmitted. The generated keys are deterministic; for any given ID,
    password, and strength combination the same keys will always be returned.
  EOF

  spec.homepage      = 'https://github.com/grempe/session-keys-rb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rbnacl', '~> 3.4.0'
  spec.add_dependency 'rbnacl-libsodium', '~> 1.0'
  spec.add_dependency 'zxcvbn-ruby', '~> 0.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'coco', '~> 0.14'
  spec.add_development_dependency 'wwtd', '~> 1.3'
end
