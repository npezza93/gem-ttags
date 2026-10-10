## RubyGems Automatic ttags Invoker

Automatically generates tag files for gems when they are installed
using ttags which generates tags based on Tree Sitter. Tree Sitter
is far better at generating tags than ctags is and is comparable to ripper-tags
but is easy to work with and can be extended to more languages like Javascript
and Rust.

## Installation

Install a build of [ttags](https://github.com/npezza93/ttags) that supports
`--files-from` and `--null` (check `ttags --help`). These options are available
on ttags `main`; the published 0.4.2 release does not support them. Until a
release includes them, install from the repository:

    cargo install --git https://github.com/npezza93/ttags --locked

gem-ttags streams NUL-separated file paths to ttags through stdin, so large
gems do not exceed the operating system's command-line size limit. Spaces,
newlines, and shell characters in file paths are passed literally. The same
Ruby files throughout each gem (including nested engines) are indexed.

Now all that's left to do is install gem-ttags and perform a one-off indexing of
the gems that are already installed:

    gem install gem-ttags
    gem ttags

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Run `bundle exec rake test` for the regression tests. To also exercise a real
compatible ttags executable, run `TTAGS=/absolute/path/to/ttags bundle exec rake test`.
The tests can also run directly with `ruby -Ilib:test test/ttags_command_test.rb`
when Minitest is available.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/npezza93/gem-ttags. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/npezza93/gem-ttags/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Gem::Ttags project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/npezza93/gem-ttags/blob/main/CODE_OF_CONDUCT.md).
