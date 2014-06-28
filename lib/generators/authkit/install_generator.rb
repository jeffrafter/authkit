require 'rails/generators'
require 'rails/generators/active_record'

module Authkit
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "An auth system for your Rails app"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    class_option :oauth, type: :boolean
    class_option :amazon, type: :boolean
    class_option :facebook, type: :boolean
    class_option :flickr, type: :boolean
    class_option :foursquare, type: :boolean
    class_option :github, type: :boolean
    class_option :google, type: :boolean
    class_option :instagram, type: :boolean
    class_option :linkedin, type: :boolean
    class_option :paypal, type: :boolean
    class_option :soundcloud, type: :boolean
    class_option :tumblr, type: :boolean
    class_option :twitter, type: :boolean
    class_option :vimeo, type: :boolean
    class_option :all, type: :boolean

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_authkit
      generate_migration("create_users")
      generate_migration("add_authkit_fields_to_users")
      generate_migration("create_auths") if oauth?

      # Ensure the destination structure
      empty_directory "app"
      empty_directory "app/models"
      empty_directory "app/forms"
      empty_directory "app/controllers"
      empty_directory "app/helpers"
      empty_directory "app/views"
      empty_directory "app/views/users"
      empty_directory "app/views/sessions"
      empty_directory "app/views/password_reset"
      empty_directory "app/views/password_change"
      empty_directory "spec"
      empty_directory "spec/factories"
      empty_directory "spec/models"
      empty_directory "spec/controllers"
      empty_directory "lib"

      # Fill out some templates (for now, this is just straight copy)
      template "app/models/user.rb", "app/models/user.rb"
      template "app/controllers/users_controller.rb", "app/controllers/users_controller.rb"
      template "app/controllers/signup_controller.rb", "app/controllers/signup_controller.rb"
      template "app/controllers/sessions_controller.rb", "app/controllers/sessions_controller.rb"
      template "app/controllers/password_reset_controller.rb", "app/controllers/password_reset_controller.rb"
      template "app/controllers/password_change_controller.rb", "app/controllers/password_change_controller.rb"
      template "app/controllers/email_confirmation_controller.rb", "app/controllers/email_confirmation_controller.rb"

      if oauth?
        template "app/models/auth.rb", "app/models/auth.rb"
        template "app/controllers/auths_controller.rb", "app/controllers/auths_controller.rb"
        template "app/helpers/auths_helper.rb", "app/helpers/auths_helper.rb"
      end

      template "app/forms/signup.rb", "app/forms/signup.rb"

      template "spec/factories/user.rb", "spec/factories/user.rb"
      template "spec/models/user_spec.rb", "spec/models/user_spec.rb"
      template "spec/forms/signup_spec.rb", "spec/forms/signup_spec.rb"
      template "spec/controllers/application_controller_spec.rb", "spec/controllers/application_controller_spec.rb"
      template "spec/controllers/users_controller_spec.rb", "spec/controllers/users_controller_spec.rb"
      template "spec/controllers/signup_controller_spec.rb", "spec/controllers/signup_controller_spec.rb"
      template "spec/controllers/sessions_controller_spec.rb", "spec/controllers/sessions_controller_spec.rb"
      template "spec/controllers/password_reset_controller_spec.rb", "spec/controllers/password_reset_controller_spec.rb"
      template "spec/controllers/password_change_controller_spec.rb", "spec/controllers/password_change_controller_spec.rb"
      template "spec/controllers/email_confirmation_controller_spec.rb", "spec/controllers/email_confirmation_controller_spec.rb"

      template "lib/email_format_validator.rb", "lib/email_format_validator.rb"
      template "lib/username_format_validator.rb", "lib/username_format_validator.rb"
      template "lib/full_name_splitter.rb", "lib/full_name_splitter.rb"

      template "config/initializers/omniauth.rb", "config/initializers/omniauth.rb" if oauth?

      template "app/views/signup/new.html.erb", "app/views/signup/new.html.erb"
      template "app/views/sessions/new.html.erb", "app/views/sessions/new.html.erb"

      # Don't treat these like templates
      copy_file "app/views/users/edit.html.erb", "app/views/users/edit.html.erb"
      copy_file "app/views/users/complete.html.erb", "app/views/users/complete.html.erb"
      copy_file "app/views/password_reset/show.html.erb", "app/views/password_reset/show.html.erb"
      copy_file "app/views/password_change/show.html.erb", "app/views/password_change/show.html.erb"
      copy_file "app/views/auths/connect.html.erb", "app/views/auths/connect.html.erb" if oauth?

      # We don't want to overwrite this file and we may have a protected section so we want it at the bottom
      insert_at_end_of_class "app/controllers/application_controller.rb", "app/controllers/application_controller.rb"

      # Technically, we aren't inserting this at the end of the class, but the end of the RSpec::Configure
      insert_at_end_of_class "spec/spec_helper.rb", "spec/spec_helper.rb"

      insert_at_end_of_file "config/initializers/filter_parameter_logging.rb", "config/initializers/filter_parameter_logging.rb"

      # Setup the routes
      route "get   '/email/confirm/:token', to: 'email_confirmation#show', as: :confirm"

      route "post  '/password/reset', to: 'password_reset#create'"
      route "get   '/password/reset', to: 'password_reset#show', as: :password_reset"
      route "post  '/password/change/:token', to: 'password_change#create'"
      route "get   '/password/change/:token', to: 'password_change#show', as: :password_change"

      if oauth?
        route "get   '/connect', to: 'auths#connect', as: :connect"
        route "get   '/auth/:provider/callback', to: 'auths#callback', as: :callback"
        route "get   '/auth/failure', to: 'auths#failure', as: :failure"
        route "get   '/auth/disconnect/:id', to: 'auths#disconnect', as: :disconnect"
      end

      route "post  '/signup', to: 'signup#create'"
      route "get   '/signup', to: 'signup#new', as: :signup"
      route "get   '/signup/complete', to: 'users#complete', as: :users_complete"
      route "get   '/logout', to: 'sessions#destroy', as: :logout"
      route "post  '/login', to: 'sessions#create'"
      route "get   '/login', to: 'sessions#new', as: :login"

      route "patch '/account', to: 'users#update'"
      route "get   '/account', to: 'users#edit', as: :user"

      # Support for has_secure_password and has_one_time_password
      gem "active_model_otp"
      gem "bcrypt-ruby", '~> 3.1.2'

      # RSpec needs to be in the development group to be used in generators
      gem_group :test, :development do
        gem "rspec-rails"
        gem "shoulda-matchers"
        gem "factory_girl_rails"
      end

      if oauth?
        gem 'omniauth'
        gem 'omniauth-google-oauth2' if provider?(:google)
        gem 'omniauth-facebook' if provider?(:facebook)
        gem 'omniauth-twitter' if provider?(:twitter)
        gem 'omniauth-tumblr' if provider?(:tumblr)
        gem 'omniauth-soundcloud' if provider?(:soundcloud)

        # Support for google client apis
        if provider?(:google)
          gem 'google-api-client', :require => 'google/api_client'
          gem 'faraday', '~> 0.9.0'
          gem 'faraday_middleware'
        end
      end
    end

    protected

    def oauth?
      options[:oauth]
    end

    def provider?(service)
      options[service] || options[:all]
    end

    def providers
      result = []
      %w(amazon
         facebook
         flickr
         foursquare
         github
         google
         instagram
         linkedin
         paypal
         soundcloud
         tumblr
         twitter
         vimeo).each do |provider|
        result << provider.to_sym if provider?(provider.to_sym)
      end
      result
    end

    def formatted_providers
      {
        amazon: "Amazon",
        facebook: "Facebook",
        flickr: "Flickr",
        foursquare: "Foursquare",
        github: "GitHub",
        google: "Google",
        instagram: "Instagram",
        linkedin: "LinkedIn",
        paypal: "Paypal",
        soundcloud: "SoundCloud",
        tumblr: "Tumblr",
        twitter: "Twitter",
        vimeo: "Vimeo"
      }
    end

    def font_awesome_icons
      {
        amazon: "amazon",
        facebook: "facebook",
        flickr: "flickr",
        foursquare: "foursquare",
        github: "github",
        google: "google",
        instagram: "instagram",
        linkedin: "linkedin",
        paypal: "paypal",
        soundcloud: "soundcloud",
        tumblr: "tumblr",
        twitter: "twitter",
        vimeo: "vimeo"
      }
    end

    def insert_at_end_of_file(filename, source)
      source = File.expand_path(find_in_source_paths(source.to_s))
      context = instance_eval('binding')
      content = ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
      insert_into_file filename, "#{content}\n", before: /\z/
    end

    def insert_at_end_of_class(filename, source)
      source = File.expand_path(find_in_source_paths(source.to_s))
      context = instance_eval('binding')
      content = ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
      insert_into_file filename, "#{content}\n", before: /end\n*\z/
    end

    def generate_migration(filename)
      if self.class.migration_exists?("db/migrate", "#{filename}")
        say_status "skipped", "Migration #{filename}.rb already exists"
      else
        migration_template "db/migrate/#{filename}.rb", "db/migrate/#{filename}.rb"
      end
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end
  end
end
