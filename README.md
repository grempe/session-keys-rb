# sessionKeys (Ruby)

[![Gem Version](https://badge.fury.io/rb/session_keys.svg)](https://badge.fury.io/rb/session_keys)
[![Build Status](https://travis-ci.org/grempe/session-keys-rb.svg?branch=master)](https://travis-ci.org/grempe/session-keys-rb)
[![Coverage Status](https://coveralls.io/repos/github/grempe/session-keys-rb/badge.svg?branch=master)](https://coveralls.io/github/grempe/session-keys-rb?branch=master)
[![Code Climate](https://codeclimate.com/github/grempe/session-keys-rb/badges/gpa.svg)](https://codeclimate.com/github/grempe/session-keys-rb)
[![Inline docs](http://inch-ci.org/github/grempe/session-keys-rb.svg?branch=master)](http://inch-ci.org/github/grempe/session-keys-rb)

`sessionKeys` is a cryptographic tool for the generation of unique user IDs,
and NaCl compatible [Curve25519](https://cr.yp.to/ecdh.html) encryption, and
[Ed25519](http://ed25519.cr.yp.to) digital signature keys using Ruby.

It is compatible with [grempe/session-keys-js](https://github.com/grempe/session-keys-js)
which can generates identical IDs and crypto keys using Javascript when given the
same username and passphrase values. Both libraries have extensive tests to
ensure they remain interoperable.

The strength of the system lies in the fact that the keypairs are derived from passing an identifier such as a username or email address, and a high-entropy passphrase through the SHA256 cryptographic one-way hash function, and then 'stretching' that username/password into strong key material using the scrypt key derivation function.

For an overview of the security design, please see the README for the companion
project [grempe/session-keys-js](https://github.com/grempe/session-keys-js)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'session_keys'
```

And then execute:

```text
$ bundle
```

Or install it yourself as:

```text
$ gem install session_keys
```

## Usage

```ruby
require 'session_keys'

SessionKeys.generate('user@example.com', 'my strong passphrase')

{
  id: '...',
  byte_keys: [...],
  hex_keys: [...],
  nacl_encryption_key_pairs: [...],
  nacl_encryption_key_pairs_base64: [...],
  nacl_signing_key_pairs: [...],
  nacl_signing_key_pairs_base64: [...],
  process_time: 250
}

```

Security Note : Each Array will contain eight values. Since each value at a
particular Array index is derived from the same key material it is recommended
to choose the different key types you need from different Array indexes. This
ensures that each key type was not derived from the same value.

```
# uuid : array index 0
output.hex_keys[0]

# encryption keypair : array index 1
output.nacl_encryption_key_pairs[1]

# signing keypair : array index 2
output.nacl_signing_key_pairs[2]
```

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
