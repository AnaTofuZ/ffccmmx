# Ffccmmx

Ffccmmx is a Firebase Cloud Messaging (FCM) client for Ruby, built on top of the [httpx](https://rubygems.org/gems/httpx).
It is based on the original [fcmpush gem](https://rubygems.org/gems/fcmpush).

By leveraging httpx, this gem enables HTTP/2 communication while maintaining an interface that is almost identical to fcmpush.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

### Configuration

```ruby
Ffccmmx.configure do |config|
  config.scope = ["https://www.googleapis.com/auth/cloud-platform"]
  config.json_key_io = StringIO.new('{"key": "value"}')
  config.proxy = "http://proxy.example.com"
  config.httpx_options = {
    timeout: {
      connect_timeout:  5,  
    },
  }
end
```

or You can use environment variables:

```bash
export GOOGLE_ACCOUNT_TYPE = 'service_account'
export GOOGLE_CLIENT_ID = '000000000000000000000'
export GOOGLE_CLIENT_EMAIL = 'xxxx@xxxx.iam.gserviceaccount.com'
export GOOGLE_PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n'
```

or You can use a JSON key file:

```ruby
Ffccmmx.configure do |config|
  config.json_key_io = File.open('/path/to/your/service_account_credentials.json')
end
```

### Pushing Messages

```ruby
@client = Ffccmmx.new(project_id)
notification_message = { 
  message: {
    token: device_token,
    notification: {
      title: "test title",
      body: "test body"
    }
  }
}
response = @client.push(notification_message)
response.json
```

response is an instance of `Ffccmmx::Response`, which contains the response from the FCM server. You can access the JSON response using `response.json`.
The Fcmpush response uses symbols for its keys, while the Ffccmmx response uses strings.

### Subscribe

```ruby
@client = Ffccmmx.new(project_id)
response = @client.subscribe('/topics/test_topic', device_token)
```

### Unsubscribe

```ruby
@client = Ffccmmx.new(project_id)
response = @client.unsubscribe('/topics/test_topic', device_token)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AnaTofuZ/ffccmmx. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/AnaTofuZ/ffccmmx/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ffccmmx project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/AnaTofuZ/ffccmmx/blob/master/CODE_OF_CONDUCT.md).
