# Authkit

A gem for installing auth into you app.

## Why?

There are lots of great authentication gems out there; devise? clearance? restful_auth? All of these seek to solve the problem of adding authentication to your application but they all share one philosophy: you shouldn't need to think about authentication to build your app. Because of this, the developer may spend more time trying to customize the tools for the few cases when the application needs to do something different.

Authkit takes the opposite stance: auth belongs in your app. It is important and it is specific to your app. It only includes generators and installs itself with some specs. You customize it. Everything is right where you would expect it to be.

Of course, this stance can be very dangerous as it relies on the application developer to not interfere with the authentication mechanisms, and it makes introducing security patches difficult. This is the trade-off. Generally speaking the approaches taken within authkit are designed for the early life-cycle of a small to medium application. It can support much larger platforms, but it is likely that larger platforms will need centralized authentication mechanisms that go beyond the scope of this project.

## Features

Authkit supports Ruby down to version 1.9 but targets 2.0. It is built for Rails 4. It is possible that it could support Rails 3.x (currently it relies on strong parameters and the Rails 4 message verifier and `secret_key_base`). Some of the features include:

  * Signup (username or email)
  * Login/Logout
  * Database backed unique constraints
  * Email confirmation (you must connect a mailer, see below)
  * Password reset (you must connect a mailer, see below)
  * One time password / Two factor authentication
  * Token support
  * Remember me
  * User sessions per device
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

If there is a feature you don't want to use, you just have to go and delete the generated code. It is your application to customize.

More information is available in [FEATURES](FEATURES.md).

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

    app/models/user.rb
    app/controllers/users_controller.rb
    app/controllers/signup_controller.rb
    app/controllers/sessions_controller.rb
    app/controllers/password_reset_controller.rb
    app/controllers/password_change_controller.rb
    app/controllers/email_confirmation_controller.rb
    app/forms/signup.rb
    app/views/signup/new.html.erb
    app/views/users/edit.html.erb
    app/views/sessions/new.html.erb
    app/views/password_reset/show.html.erb
    app/views/password_change/show.html.erb

And will insert a series of helpers into your application controller:

    insert  app/controllers/application_controller.rb

And create corresponding specs:

    spec/factories/user.rb
    spec/models/user_spec.rb
    spec/forms/signup_spec.rb
    spec/controllers/application_controller_spec.rb
    spec/controllers/users_controller_spec.rb
    spec/controllers/signup_controller_spec.rb
    spec/controllers/sessions_controller_spec.rb
    spec/controllers/password_reset_controller_spec.rb
    spec/controllers/password_change_controller_spec.rb
    spec/controllers/email_confirmation_controller_spec.rb

And a nice helpful email format validator:

    create  lib/email_format_validator.rb

It will also generate a set of routes:

    route  get   '/email/confirm/:token', to: 'email_confirmation#show', as: :confirm
    route  post  '/password/reset', to: 'password_reset#create'
    route  get   '/password/reset', to: 'password_reset#show', as: :password_reset
    route  post  '/password/change/:token', to: 'password_change#create'
    route  get   '/password/change/:token', to: 'password_change#show', as: :password_change
    route  post  '/signup', to: 'signup#create'
    route  get   '/signup', to: 'signup#new', as: :signup
    route  get   '/logout', to: 'sessions#destroy', as: :logout
    route  get   '/login', to: 'sessions#new', as: :login
    route  patch '/account', to: 'users#update'
    route  get   '/account', to: 'users#edit', as: :user

    route  resources :sessions, only: [:new, :create, :destroy]
    route  resources :users, only: [:create]

And will add some gems to your Gemfile:

    gemfile  active_model_otp
    gemfile  bcrypt-ruby (~> 3.1.2)
    gemfile  rspec-rails, :test, :development
    gemfile  shoulda-matchers, :test, :development
    gemfile  factor_girl_rails, :test, :development

Once you have this installed you can remove the gem, however you may want to keep the gem installed in development as you will be able to update it and check for security bulletins.

You'll need to migrate your database (check the migrations before you do):

    rake db:migrate

You'll also need to connect your mailers for sending password reset instructions and email confirmations. (See the TODO in `user.rb`)

## NOTES

Authkit has a number of conventions and requirements that should be noted.

* SSL expected
* secure cookies
* password complexity is not robust
* users do not need to confirm their email address to proceed
* need a root route

### SSL

It is expected that your application be protected by SSL. Though it is possible to segregate your application into SSL/non-SSL areas, Authkit utilizes cookies to store remember token information and assumes that sessions are backed by a cookie store. Because of this you must use SSL to protect against Session Hijacking attacks. Cookies are marked as secure only in the production environment (see `ApplicationController#set_remember_cookie`). If you are using Authkit in a staging environment you might need to adjust this.

### Password and username validation

There is only a minimal amount of validation on the password. Because of this users can choose poor passwords (which are not complex or are overly common). To improve this you can adjust the validation in `user.rb`:

    validates :password, presence: true, confirmation: true, length: {minimum: 6}, if: :password_set?

### Confirmation not required by default

By default, users can begin using the system without confirming their email address. This simplifies the onboarding process, however it means that malicious users may be operating under false pretense. You can change this by adding a check to `ApplicationController#require_login`:

    def require_login
      deny_user(nil, login_path) unless logged_in?
      deny_user("You need to confirm your email address before proceeding", root_path) unless current_user.email_confirmed?
    end

And then in `user.rb`:

    def email_confirmed?
      self.confirmation_token.blank?
    end

### Root route

Additionally, there are several redirects that occur within Authkit (when you have successfully logged in or logged out, etc.). By default the user is redirected to the root_path in these cases. Because of this, you must define a `root` route in your `config/routes.rb`.

## Tokens

Authkit makes use of several kinds of tokens:

* remember tokens
* reset password tokens
* confirmation tokens (email)
* unlock tokens
* one time use password tokens
* api tokens

All of the tokens are generated using `SecureRandom.urlsafe_base64(32)`. Each token has a unique index within the database to prevent conflicts but collisions are very unlikely (1/64^32). In the event that a conflict does occur an `ActiveRecord::StatementInvalid` or `ActiveRecord::RecordNotUnique` exeception will be raised.

It has been suggested that tokens are essentially passwords (though quite complex ones) and that they should not be stored directly in the database. Instead tokens should be stored using Bcrypt (and stored as a token_digest) to prevent someone with read access from gaining control of an account. This is not currently implemented.

Failed attempts are not currently tracked for tokens. Token misses could be used to contribute to `failed_attempts`, however in certain circumstances this could be used to disrupt service by locking accounts. Ideally, invalid tokens would be logged centrally and an existing tool like `fail2ban` could be used to restrict access.

You can adjust the default token expiry in `user.rb`.

Each of these tokens utilizes a different strategy to protect it from attacks.

### Remember tokens

Remember tokens are re-generated every-time a user logs in and the resulting token is stored in a cookie on the user's device (i.e., the browser). The cookie is encrypted, signed and only delivered over secure connections (see SSL above).

Because the token is regenerated on every login, any existing remember cookies (for instance, on another device) will be immediately invalidated.

Because the cookie mechanism uses `ActiveSupport#MessageVerifier` it is dependent on the security of that class. By default that class securely compares strings and decrypts using strong secret keys (the Rails `secret_key_base` specifically). This protects against timing attacks. Once the verified token is obtained, it can be safely used as part of a database query.

Changing your `secret_key_base` will invalidate all existing cookies including all remember cookies. This may be a feature as it is likely that you would want to invalidate all sessions in the event your secret key was compromised.

Because the token is not used directly (it must be included in the cookie), even with read access to the database an attacker cannot login without also having the ability to sign the remember cookie.

Once the user logs out the token is cleared and is no longer available.

### Reset password tokens

When a user forgets their password they can request a password reset so that they can change their password. A new `reset_password_token` is generated when a request is made and an email is sent to the corresponding email address.

It is possible to encode the resulting token using the message verifier which could later be used to validate that the token really was generated by the system.

Instead the system employs a two-token approach, using both the corresponding email address and the `reset_password_token`. The token is paired with an email parameter so that the user can be found in the database. Once found the tokens can be securely compared to prevent timing attacks. The email address is chosen over the user id because the reset request was generated using the email address and thus is already known. Using the id would increase information leakage.

Again, if you are not using SSL this means that the email address and token will be visible in the path information of requests.

Once the password is changed, the token is cleared and is no longer available.

### Confirmation tokens

When a user signs up or changes their email address an email is sent to the specified address to confirm that the user really controls the email. This is done to ensure that users didn't mistype the address and also protects against malicious users impersonating well known accounts.

Like password resets, these tokens are sent directly in email. In the case of email confirmation, however it is possible to require that the user be logged in to utilize the token. Because of this the tokens can easily be compared securely to prevent timing attacks.

Once the email is confirmed, the token is cleared and is no longer available.

### Unlock tokens

Currently unlock tokens are not implemented. Once implemented unlocks will be sent to logged out users using their email address. Because of this, it is likely that any implementation of unlock tokens will function similar to password reset tokens.

### API tokens

Currently API tokens are not implemented. An API token implementation will not have access to a current user. Because of this the API token system can take one of two approaches:

1. Using a `ActiveSupport::MessageVerifier` to generate verified tokens.
2. Using a two token approach in the form of `api_access_key` (which is used for database lookups) and `api_secret_token` (which is compared securely).

Any implementation of token authentication will likely need to support multiple tokens per account (i.e. a Tokens model). This also allows the user to directly revoke keys.

In the case of API access, storing a digest of the token is not practical. Bcrypt digesting is slow and would add a significant amount of overhead if used on every request (on average 90ms with the default 10 stretches).

Additionally, storing only the digest means that a user cannot login to see their API tokens. They would need to be regenerated. This might be considered a feature.

## User session expiry

Users sessions and the remember tokens attached to them do not expire by default. For most sites this type of behavior is fine. If the user chooses to remember their session on the current device then that shouldn't change based on an arbitrary timeout, but only if the user revokes the session or logs out. However on some sensitive sites you may want to change this behavior. You can do this by making the cookie expire after a specific amount of time or by making the token or session expire based on a rolling time window:

      scope :active, -> { where('(accessed_at IS NULL OR accessed_at >= ?)', 2.weeks.ago).where(revoked_at: nil, logged_out_at: nil) }


## What's missing

There is a significant amount of functionality that is currently unimplemented:

* Use Bcrypt and token digests instead of storing actual tokens in the database (defense in depth).
* Full name option (instead of first name and last name)
* Notification for changes to account (security settings changed)
* Ability to re-auth for sensitive changes (available for the current session only)
* API token support
* OAuth2 client support (but not logging in?) in the form of Facebook support, Twitter support, Google support
* OAuth2 server support
* One time password support completed
* Add Authy or Google Authenticator support
* Avatars (possibly this should be within uploadkit)
* Audit logs
* No internationalization (i18n)
* JavaScript validation for username and email availability and password complexity
* Reset all sessions on password change

## Testing

The files generated using the installer include specs. To test these you should be able to:

    $ bundle install

Then run the default task:

    $ rake

This will run the specs, which by default will generate a new Rails application, run the installer, and execute the specs in the context of that temporary application.

The specs that are generated utilize a generous amount of mocking and stubbing in an attempt to keep them fast. However, they use vanilla `rspec-rails`, meaning they are not using mocha. The two caveats are shoulda-matchers and FactoryGirl which are required. It is pretty easy to remove these dependencies, it just turned out that more people were using them than not.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
