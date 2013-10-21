# Authkit

A gem for installing auth into you app.

TODO:

Handle token expiry (for remember tokens, reset password tokens, unlock tokens and confirmation tokens)

  def self.user_from_remember_token(token)
    user = user_from_token(token)
    user = nil if user && user.remember_token_created_at < 30.days.ago
    user
  end



## Installation

Add this line to your application's Gemfile:

    gem 'authkit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install authkit

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
