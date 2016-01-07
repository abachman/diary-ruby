![travisci](https://travis-ci.org/abachman/diary-ruby.svg?branch=master)

# diary-ruby

A toy CLI app for me. Playing with encryption and the `$EDITOR` env var.

## Usage

    $ gem install diary-ruby
    $ diaryrb

    TYPE TYPE TYPE

Now you have a diary too.

You can create a config file to make it easier to manage multiple diaries.
`diaryrb` looks for a config file in ~/.diaryrb/config.yaml. Valid config
options are `passphrase` and `path`. For example:

```yaml
default:
  path: "/Users/yername/Dropbox/Documents/notes.diary"

secure.store:
  passphrase: "this is the passphrase, I put it in a config file! 82acf427f94c513f8d7f81995a549361089d903f"
  path: "~/secure.secret.diary"
```

If a config file is used, diaryrb uses the -d option to pick a diary by name:

    $ diaryrb -d default

would load the diary at `/Users/.../notes.diary`, while

    $ diaryrb -d mynotes

would create a new diary file named "mynotes" in the current directory.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/abachman/diary-ruby. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

