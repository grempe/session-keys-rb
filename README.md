# SessionKeys

[![Dependency Status](https://gemnasium.com/badges/github.com/grempe/session-keys-rb.svg)](https://gemnasium.com/github.com/grempe/session-keys-rb)
[![Build Status](https://travis-ci.org/grempe/session-keys-rb.svg?branch=master)](https://travis-ci.org/grempe/session-keys-rb)
[![Coverage Status](https://coveralls.io/repos/github/grempe/session-keys-rb/badge.svg?branch=master)](https://coveralls.io/github/grempe/session-keys-rb?branch=master)
[![Code Climate](https://codeclimate.com/github/grempe/session-keys-rb/badges/gpa.svg)](https://codeclimate.com/github/grempe/session-keys-rb)
[![Inline docs](http://inch-ci.org/github/grempe/session-keys-rb.svg?branch=master)](http://inch-ci.org/github/grempe/session-keys-rb)

SessionKeys is a cryptographic tool for the deterministic generation of
NaCl compatible [Curve25519](https://cr.yp.to/ecdh.html) encryption and
[Ed25519](http://ed25519.cr.yp.to) digital signature keys.

The strength of the system lies in the fact that the keypairs are derived from
passing an identifier, such as a username or email address, and a high-entropy
passphrase through the `SHA256` hash and the `scrypt` key derivation
functions. This means that no private key material need ever be stored to disk.
The generated keys are deterministic; for any given ID, password, and
strength combination the same keys will always be returned.

The generated ID is passed through `SHA256` and `scrypt` and is derived from
only the ID parameter your provide and a common salt.

The password is also passed through `SHA256` and `scrypt` and NaCl encryption
and signing keypairs are derived from the combination of the stretched ID,
your password, and a common salt.

## WARNING : BETA CODE

This code is new and has not yet been tested in production. Use at your own risk.
The interface should be fairly stable now but should not be considered fully
stable until v1.0.0 is released.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'session_keys'
```

And then execute:

``` text
$ bundle
```

Or install it yourself as:

``` text
$ gem install session_keys
```

### Installation Security : Signed Ruby Gem

The SessionKeys gem is cryptographically signed. To be sure the gem you install hasn’t
been tampered with you can install it using the following method:

Add my public key (if you haven’t already) as a trusted certificate

``` text
# Caveat: Gem certificates are trusted globally, such that adding a
# cert.pem for one gem automatically trusts all gems signed by that cert.
gem cert --add <(curl -Ls https://raw.github.com/grempe/session-keys-rb/master/certs/gem-public_cert_grempe.pem)
```

To install, it is possible to specify either `HighSecurity` or `MediumSecurity`
mode. Since the `session_keys` gem depends on one or more gems that are not cryptographically
signed you will likely need to use `MediumSecurity`. You should receive a warning
if any signed gem does not match its signature.

``` text
# All dependent gems must be signed and verified.
gem install session_keys -P HighSecurity
```

``` text
# All signed dependent gems must be verified.
gem install session_keys -P MediumSecurity
```

``` text
# Same as above, except Bundler only recognizes
# the long --trust-policy flag, not the short -P
bundle --trust-policy MediumSecurity
```

You can [learn more about security and signed Ruby Gems](http://guides.rubygems.org/security/).

### Installation Security : Signed Git Commits

Most, if not all, of the commits and tags to the repository for this code are
signed with my PGP/GPG code signing key. I have uploaded my code signing public
keys to GitHub and you can now verify those signatures with the GitHub UI.
See [this list of commits](https://github.com/grempe/session-keys-rb/commits/master)
and look for the `Verified` tag next to each commit. You can click on that tag
for additional information.

You can also clone the repository and verify the signatures locally using your
own GnuPG installation. You can find my certificates and read about how to conduct
this verification at [https://www.rempe.us/keys/](https://www.rempe.us/keys/).

## Usage

``` ruby
keys = SessionKeys.generate('user@example.com', 'my strong passphrase')
#=> {...}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
[https://github.com/grempe/session-keys-rb](https://github.com/grempe/session-keys-rb).
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Legal

### Copyright

(c) 2016 Glenn Rempe <[glenn@rempe.us](mailto:glenn@rempe.us)> ([https://www.rempe.us/](https://www.rempe.us/))

### License

The gem is available as open source under the terms of
the [MIT License](http://opensource.org/licenses/MIT).

### Warranty

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the LICENSE.txt file for the
specific language governing permissions and limitations under
the License.
