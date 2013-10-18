require 'rails/generators'

module Authkit
  class InstallGenerator < Rails::Generators::Base
    desc "An auth system for your Rails app"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_authkit
      generate_migration("create_users")
      generate_migration("add_authkit_fields_to_users")
    end

    protected

    def generate_migration(filename)
      if self.class.migration_exists?("db/migrate", "#{filename}")
        say_status("skipped", "Migration #{filename}.rb already exists")
      else
        migration_template "migrations/#{filename}.rb", "db/migrate/#{filename}.rb"
      end
    end
  end
end
