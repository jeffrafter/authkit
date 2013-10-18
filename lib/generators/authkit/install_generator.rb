require 'rails/generators'

module Authkit
  class InstallGenerator < Rails::Generators::Base
    desc "An auth system for your Rails app"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_authkit
    end
  end
end
