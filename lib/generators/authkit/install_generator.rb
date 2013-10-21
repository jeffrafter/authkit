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
      empty_directory "test"
      empty_directory "test/models"
      empty_directory "test/controllers"
      empty_directory "lib"

      template "app/models/user.rb", "app/models/user.rb"
      template "app/controllers/users_controller.rb", "app/controllers/users_controller.rb"
      template "app/controllers/sessions_controller.rb", "app/controllers/sessions_controller.rb"
      template "app/controllers/passwords_controller.rb", "app/controllers/passwords_controller.rb"

      template "test/models/user_test.rb", "test/models/user_test.rb"
      template "test/controllers/users_controller_test.rb", "test/controllers/users_controller_test.rb"
      template "test/controllers/sessions_controller_test.rb", "test/controllers/sessions_controller_test.rb"
      template "test/controllers/passwords_controller_test.rb", "test/controllers/passwords_controller_test.rb"

      template "lib/email_format_validator.rb", "lib/email_format_validator"

      insert_at_end_of_class "app/controllers/application_controller.rb", "app/controllers/application_controller.rb"

      route "get '/signup', to: 'users#new', as: :signup"
      route "get '/logout', to: 'sessions#destroy', as: :logout"
      route "get '/login', to: 'sessions#new', as: :login"

      route "resources :sessions, only: [:new, :create, :destroy]"
      route "resources :users"

      gem "active_model_otp"

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
