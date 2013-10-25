# Authkit

A gem for installing auth into you app.

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

Once you have this installed you can remove the gem. You'll also need to connect your mailers
for sending password reset instructions and email confirmations. (See the TODO in +user.rb+)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
