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

      empty_directory "app"
      empty_directory "app/models"
      empty_directory "app/controllers"
      empty_directory "app/views"
      empty_directory "app/views/users"
      empty_directory "app/views/sessions"
      empty_directory "app/views/change_password"
      empty_directory "app/views/forgot_password"
      empty_directory "spec"
      empty_directory "spec/models"
      empty_directory "spec/controllers"
      empty_directory "lib"

      template "app/models/user.rb", "app/models/user.rb"
      template "app/controllers/users_controller.rb", "app/controllers/users_controller.rb"
      template "app/controllers/sessions_controller.rb", "app/controllers/sessions_controller.rb"
      template "app/controllers/forgot_password_controller.rb", "app/controllers/forgot_password_controller.rb"
      template "app/controllers/change_password_controller.rb", "app/controllers/change_password_controller.rb"

      copy_file "app/views/users/new.html.erb", "app/views/users/new.html.erb"
      copy_file "app/views/users/edit.html.erb", "app/views/users/edit.html.erb"
      copy_file "app/views/sessions/new.html.erb", "app/views/sessions/new.html.erb"
      copy_file "app/views/forgot_password/show.html.erb", "app/views/forgot_password/show.html.erb"
      copy_file "app/views/change_password/show.html.erb", "app/views/change_password/show.html.erb"

      template "spec/models/user_spec.rb", "spec/models/user_spec.rb"
      template "spec/controllers/users_controller_spec.rb", "spec/controllers/users_controller_spec.rb"
      template "spec/controllers/sessions_controller_spec.rb", "spec/controllers/sessions_controller_spec.rb"
      template "spec/controllers/forgot_password_controller_spec.rb", "spec/controllers/forgot_password_controller_spec.rb"
      template "spec/controllers/change_password_controller_spec.rb", "spec/controllers/change_password_controller_spec.rb"

      template "lib/email_format_validator.rb", "lib/email_format_validator.rb"

      insert_at_end_of_class "app/controllers/application_controller.rb", "app/controllers/application_controller.rb"

      route "get  '/password/forgot', to: 'forgot_password#show', as: :forgot_password"
      route "post '/password/forgot', to: 'forgot_password#create'"
      route "get  '/password/change/:token', to: 'change_password#show', as: :change_password"
      route "post '/password/change/:token', to: 'change_password#create'"
      route "get  '/signup', to: 'users#new', as: :signup"
      route "get  '/logout', to: 'sessions#destroy', as: :logout"
      route "get  '/login', to: 'sessions#new', as: :login"

      route "resources :sessions, only: [:new, :create, :destroy]"
      route "resources :users"

      gem "active_model_otp"
      gem "bcrypt-ruby", '~> 3.0.0'

      # RSpec needs to be in the development group to be used in generators
      gem_group :test, :development do
        gem "rspec-rails"
      end

      gem_group :test do
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
      insert_into_file "app/controllers/application_controller.rb", "#{content}\n", before: /end\n*\z/
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
