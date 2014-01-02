require 'rails/generators'
require 'rails/generators/active_record'

module Authkit
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "An auth system for your Rails app"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_authkit
      generate_migration("create_users")
      generate_migration("add_authkit_fields_to_users")

      # Ensure the destination structure
      empty_directory "app"
      empty_directory "app/models"
      empty_directory "app/forms"
      empty_directory "app/controllers"
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

      # Don't treat these like templates
      copy_file "app/views/signup/new.html.erb", "app/views/signup/new.html.erb"
      copy_file "app/views/users/edit.html.erb", "app/views/users/edit.html.erb"
      copy_file "app/views/sessions/new.html.erb", "app/views/sessions/new.html.erb"
      copy_file "app/views/password_reset/show.html.erb", "app/views/password_reset/show.html.erb"
      copy_file "app/views/password_change/show.html.erb", "app/views/password_change/show.html.erb"

      # We don't want to overwrite this file and we may have a protected section so we want it at the bottom
      insert_at_end_of_class "app/controllers/application_controller.rb", "app/controllers/application_controller.rb"

      # Technically, we aren't inserting this at the end of the class, but the end of the RSpec::Configure
      insert_at_end_of_class "spec/spec_helper.rb", "spec/spec_helper.rb"

      # Need a temp root
      route "root 'welcome#index'"

      # Setup the routes
      route "get   '/email/confirm/:token', to: 'email_confirmation#show', as: :confirm"

      route "post  '/password/reset', to: 'password_reset#create'"
      route "get   '/password/reset', to: 'password_reset#show', as: :password_reset"
      route "post  '/password/change/:token', to: 'password_change#create'"
      route "get   '/password/change/:token', to: 'password_change#show', as: :password_change"

      route "post  '/signup', to: 'signup#create'"
      route "get   '/signup', to: 'signup#new', as: :signup"
      route "get   '/logout', to: 'sessions#destroy', as: :logout"
      route "post  '/login', to: 'sessions#create'"
      route "get   '/login', to: 'sessions#new', as: :login"

      route "patch '/account', to: 'users#update'"
      route "get   '/account', to: 'users#edit', as: :user"

      route "resources :sessions, only: [:new, :create, :destroy]"
      route "resources :users, only: [:create]"

      # Support for has_secure_password and has_one_time_password
      gem "active_model_otp"
      gem "bcrypt-ruby", '~> 3.1.2'

      # RSpec needs to be in the development group to be used in generators
      gem_group :test, :development do
        gem "rspec-rails"
        gem "shoulda-matchers"
        gem "factory_girl_rails"
      end
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected

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
  end
end
