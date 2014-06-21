require 'rails/generators'
require 'rails/generators/active_record'

module Authkit
  class OauthGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "Add oauth support to your Rails app"

    hook_for :amazon, type: :boolean
    hook_for :facebook, type: :boolean
    hook_for :flickr, type: :boolean
    hook_for :foursquare, type: :boolean
    hook_for :github, type: :boolean
    hook_for :google, type: :boolean
    hook_for :instagram, type: :boolean
    hook_for :linkedin, type: :boolean
    hook_for :paypal, type: :boolean
    hook_for :soundcloud, type: :boolean
    hook_for :tumblr, type: :boolean
    hook_for :twitter, type: :boolean
    hook_for :vimeo, type: :boolean
    hook_for :all, type: :boolean

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def oauth?
      true
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
      route "get   '/auth/disconnect/:id', to: 'auths#disconnect', as: :disconnect"

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
