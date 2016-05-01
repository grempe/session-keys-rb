# Gem Release Process

Don't use the `bundle exec rake release` task. It is more convenient,
but it skips the process of signing the version release task.

## Run Tests

```sh
$ bundle exec rake test
$ rake wwtd
```

## Git Push

```sh
$ git push
```

Check for regressions in automated tests:

* [https://travis-ci.org/grempe/session-keys-rb](https://travis-ci.org/grempe/session-keys-rb)
* [https://coveralls.io/github/grempe/session-keys-rb?branch=master](https://coveralls.io/github/grempe/session-keys-rb?branch=master)
* [https://codeclimate.com/github/grempe/session-keys-rb](https://codeclimate.com/github/grempe/session-keys-rb)
* [http://inch-ci.org/github/grempe/session-keys-rb](http://inch-ci.org/github/grempe/session-keys-rb)

## Bump Version Number and edit CHANGELOG.md

```sh
$ vi lib/session_keys/version.rb
$ git add lib/session_keys/version.rb
$ vi CHANGELOG.md
$ git add CHANGELOG.md
```

## Local Build and Install w/ Signed Gem

The `build` step should ask for PEM passphrase to sign gem. If it does
not ask it means that the signing cert is not present.

Add certs:

```sh
gem cert --add <(curl -Ls https://raw.github.com/grempe/session-keys-rb/master/certs/gem-public_cert_grempe.pem)
gem cert --add <(curl -Ls https://raw.githubusercontent.com/cryptosphere/rbnacl/master/bascule.cert)
```

Build:

```sh
$ rake build
Enter PEM pass phrase:
session_keys 0.1.0 built to pkg/session_keys-0.1.0.gem.
```

Install locally w/ Cert:

```sh
$ gem uninstall session_keys
$ rbenv rehash
$ gem install pkg/session_keys-0.1.0.gem -P MediumSecurity
Successfully installed session_keys-0.1.0.gem
1 gem installed
```

## Git Commit Version and CHANGELOG Changes, Tag and push to Github

```sh
$ git add lib/session_keys/version.rb
$ git add CHANGELOG.md
$ git commit -m 'Bump version v0.1.1'
$ git tag -s v0.1.1 -m "v0.1.1" SHA1_OF_COMMIT
```

Verify last commit and last tag are GPG signed:

```
$ git tag -v v0.1.0
...
gpg: Good signature from "Glenn Rempe (Code Signing Key) <glenn@rempe.us>" [ultimate]
...
```

```
$ git log --show-signature
...
gpg: Good signature from "Glenn Rempe (Code Signing Key) <glenn@rempe.us>" [ultimate]
...
```

Push code and tags to GitHub:

```
$ git push
$ git push --tags
```

## Push gem to Rubygems.org

```sh
$ gem push pkg/session_keys-0.1.0.gem
```

Verify Gem Push at [https://rubygems.org/gems/session_keys](https://rubygems.org/gems/session_keys)

## Create a GitHub Release

Specify the tag we just pushed to attach release to. Copy notes from CHANGELOG.md

[https://github.com/grempe/session-keys-rb/releases](https://github.com/grempe/session-keys-rb/releases)

## Announce Release on Twitter

The normal blah, blah, blah.
