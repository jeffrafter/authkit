require 'rails/generators'
require 'rails/generators/active_record'

module Authkit
  class OauthGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "Add oauth support to your Rails app"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_authkit
      generate_migration("create_auths")

      # Ensure the destination structure
      empty_directory "app"
      empty_directory "app/models"
      empty_directory "app/controllers"
      empty_directory "app/views"
      empty_directory "app/views/auths"
      empty_directory "config"
      empty_directory "config/initializers"

      # Fill out some templates (for now, this is just straight copy)
      template "app/models/auth.rb", "app/models/auth.rb"
      template "app/controllers/auths_controller.rb", "app/controllers/auths_controller.rb"

      template "config/initializers/omniauth.rb", "config/initializers/omniauth.rb"

      # Don't treat these like templates
      copy_file "app/views/auths/connect.html.erb", "app/views/auths/connect.html.erb"

      # Setup the routes
      route "get   '/connect', to: 'auths#connect', as: :connect"
      route "get   '/auth/:provider/callback', to: 'auths#callback', as: :callback"
      route "get   '/auth/failure', to: 'auths#failure', as: :failure"
      route "post  '/auth/disconnect', to: 'auths#disconnect', as: :disconnect"

      gem 'omniauth'
      gem 'omniauth-google-oauth2'
      gem 'omniauth-facebook'
      gem 'omniauth-twitter'
      gem 'omniauth-tumblr'
      gem 'omniauth-soundcloud'

      # Support for google client apis
      gem 'google-api-client', :require => 'google/api_client'
      gem 'faraday_middleware'
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected

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
  end
end
