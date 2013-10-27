# Authkit

A gem for installing auth into you app.

## Why?

There are lots of great authentication gems out there; devise? clearance? restful_auth?
All of these seek to solve the problem of adding authentication to your application but they all share
one philosophy: you shouldn't need to think about authentication to build your app. For me, I find I
spend way more time trying to figure out how to customize the tools for the few cases when my
application needs to do something different.

Authkit takes the opposite stance: auth belongs in your app. It is important and it is specific to your
app. It only includes generators and installs itself with some specs. You customize it. Everything
is right where you would expect it to be.

## Features

Authkit supports Ruby down to version 1.9 but targets 2.0. It is built for Rails 4. It is possible
that it could support Rails 3.x (it would need strong parameters). Some of the features include:

  * Signup (username or email)
  * Login/Logout
  * Database backed unique constraints
  * Email confirmation (you must connect a mailer, see below)
  * Password reset (you must connect a mailer, see below)
  * One time password / Two factor authentication
  * Token support
  * Remember me
  * Account page
  * Time zones
  * Do not track (DNT) support
  * Sign-in Tracking
  * Analytics (coming soon)
  * Lockout for failed attempts (coming soon)

Some possible features include:

  * Master lockout/reset
  * Visit tracking and anonymous users
  * Third party accounts
  * Installer options (test framework, security bulletins, modules)

If there is a feature you don't want to use, you just have to go and delete the generated code.
It is your application to customize.

More information is available in [FEATURES.md].

## Installation

Add this line to your application's Gemfile:

    group :development do
      gem 'authkit'
    end

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install authkit

## Usage

Once you've installed authkit you can run the generator:

    rails g authkit:install

This will add some basic migrations for the user:

    create  db/migrate/20131025001051_create_users.rb
    create  db/migrate/20131025001052_add_authkit_fields_to_users.rb

It will also create general authentication models and controllers:

    create  app/models/user.rb
    create  app/controllers/users_controller.rb
    create  app/controllers/sessions_controller.rb
    create  app/controllers/password_reset_controller.rb
    create  app/controllers/password_change_controller.rb
    create  app/controllers/email_confirmation_controller.rb
    create  app/views/users/new.html.erb
    create  app/views/users/edit.html.erb
    create  app/views/sessions/new.html.erb
    create  app/views/password_reset/show.html.erb
    create  app/views/password_change/show.html.erb

And will insert a series of helpers into your application controller:

    insert  app/controllers/application_controller.rb

And create corresponding specs:

    create  spec/models/user_spec.rb
    create  spec/controllers/application_controller_spec.rb
    create  spec/controllers/users_controller_spec.rb
    create  spec/controllers/sessions_controller_spec.rb
    create  spec/controllers/password_reset_controller_spec.rb
    create  spec/controllers/password_change_controller_spec.rb
    create  spec/controllers/email_confirmation_controller_spec.rb

And a nice helpful email format validator:

    create  lib/email_format_validator.rb

It will also generate a set of routes:

    route  get  '/email/confirm/:token', to: 'email_confirmation#show', as: :confirm
    route  post '/password/reset', to: 'password_reset#create'
    route  get  '/password/reset', to: 'password_reset#show', as: :password_reset
    route  post '/password/change/:token', to: 'password_change#create'
    route  get  '/password/change/:token', to: 'password_change#show', as: :password_change
    route  get  '/signup', to: 'users#new', as: :signup
    route  get  '/logout', to: 'sessions#destroy', as: :logout
    route  get  '/login', to: 'sessions#new', as: :login
    route  put  '/account', to: 'users#update'
    route  get  '/account', to: 'users#edit', as: :user

    route  resources :sessions, only: [:new, :create, :destroy]
    route  resources :users, only: [:new, :create]

And will add some gems to your Gemfile:

    gemfile  active_model_otp
    gemfile  bcrypt-ruby (~> 3.0.0)
    gemfile  rspec-rails, :test, :development
    gemfile  shoulda-matchers, :test, :development

Once you have this installed you can remove the gem, however you may want to
keep the gem installed in development as you will be able to update it
and check for security bulletins.

You'll need to migrate your database (check the migrations before you do):

    rake db:migrate

You'll also need to connect your mailers for sending password reset instructions
and email confirmations. (See the TODO in +user.rb+)

## Testing

The files generated using the installer include specs. To test these you should be
able to:

    $ bundle install

Then run the default task:

    $ rake

This will run the specs, which by default will generate a new Rails application,
run the installer, and execute the specs in the context of that temporary
application.

The specs that are generated utilize a generous amount of mocking and stubbing in
an attempt to keep them fast. However, they use vanilla +rspec-rails+, meaning
they are not using FactoryGirl, or mocha. The one caveat is shoulda-matchers
which are required.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
