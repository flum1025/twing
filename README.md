# Twing

Pluginable Twitter Application

## Installation

    $ gem install twing

## Usage

    $ twing -s setting.yml

### Configuration File

Configuration file is YAML format file.

Example

```yaml
debug: false
log_dir: /tmp/log
mode: home_timeline
twitter:
  api_key:
    consumer_key: CONSUMER_KEY
    consumer_secret: CONSUMER_SECRET
    access_token: ACCESS_TOKEN
    access_token_secret: ACCESS_TOKEN_SECRET
  home_timeline_options:
    query:
      timeline_count: 200
      exclude_replies: false
    interval: 60
  filter_options:
    follow: '111111111,222222222'
redis:
  config:
    host: localhost
    port: 6379
  namespace: hoge
require:
  - require_module_name
modules:
  module_name:
    module_setting: hoge
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Make a new plugin

There are two ways.

- Single file
- gem

#### Single file

Example

```ruby:test_module.rb
require 'twing/modules/base'

class NewPlugin < Twing::Modules::Base
  def on_message(object)
    case object
    when Twitter::Tweet
      puts object.text
    end
  end
end

Twing.on_init do |app|
  app.receivers.add(NewPlugin)
end
```

Add values to the following section of the configuration file.

```yaml
require: path_to_test_module.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/flum1025/twing. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Twing project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/flum1025/twing/blob/master/CODE_OF_CONDUCT.md).
