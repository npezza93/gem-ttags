## RubyGems Automatic ttags Invoker

Automatically generates tag files for gems when they are installed
using ttags which generates tags based on Tree Sitter. Tree Sitter
is far better at generating tags than ctags is and is comparable to ripper-tags
but is easy to work with and can be extended to more languages like Javascript
and Rust.

## Installation

If you haven't already, install [ttags](https://github.com/npezza93/ttags).
Now all that's left to do is install gem-ttags and perform a one-off indexing of
the gems that are already installed:

    gem install gem-ttags
    gem ttags

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/npezza93/gem-ttags. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/npezza93/gem-ttags/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Gem::Ttags project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/npezza93/gem-ttags/blob/main/CODE_OF_CONDUCT.md).
