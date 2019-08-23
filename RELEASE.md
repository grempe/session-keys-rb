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

- [https://travis-ci.org/grempe/session-keys-rb](https://travis-ci.org/grempe/session-keys-rb)
- [https://coveralls.io/github/grempe/session-keys-rb?branch=master](https://coveralls.io/github/grempe/session-keys-rb?branch=master)
- [https://codeclimate.com/github/grempe/session-keys-rb](https://codeclimate.com/github/grempe/session-keys-rb)
- [http://inch-ci.org/github/grempe/session-keys-rb](http://inch-ci.org/github/grempe/session-keys-rb)

## Bump Version Number and edit CHANGELOG.md

```sh
$ vi lib/session_keys/version.rb
$ git add lib/session_keys/version.rb
$ vi CHANGELOG.md
$ git add CHANGELOG.md
```

## Git Commit Version and CHANGELOG Changes, Tag and push to Github

```sh
$ bundle exec rake build
$ git commit -m 'Bump version v2.0.0'
$ git tag -s v2.0.0 -m "v2.0.0" SHA1_OF_COMMIT
```

Verify last commit and last tag are GPG signed:

```
$ git tag -v v2.0.0
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
$ gem push pkg/session_keys-2.0.0.gem
```

Verify Gem Push at [https://rubygems.org/gems/session_keys](https://rubygems.org/gems/session_keys)

## Create a GitHub Release

Specify the tag we just pushed to attach release to. Copy notes from CHANGELOG.md

[https://github.com/grempe/session-keys-rb/releases](https://github.com/grempe/session-keys-rb/releases)

## Announce Release on Twitter

The normal blah, blah, blah.
