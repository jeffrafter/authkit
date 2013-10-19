require "bundler/gem_tasks"
require 'rake/testtask'

gem_name = :authkit

Rake::TestTask.new(:test => ["generator:cleanup", "generator:prepare", "generator:#{gem_name}"]) do |task|
#Rake::TestTask.new(:test) do |task|
  task.libs << "lib" << "test"
  task.pattern = "test/**/*_test.rb"
  task.verbose = true
end

namespace :test do
  Rake::TestTask.new(:database => ["generator:cleanup", "generator:prepare", "generator:database", "generator:#{gem_name}"]) do |task|
    task.libs << "lib" << "test"
    task.pattern = "test/**/*_test.rb"
    task.verbose = true
  end
end

namespace :generator do
  desc "Cleans up the test app before running the generator"
  task :cleanup do
    FileUtils.rm_rf("test/tmp/sample")
  end

  desc "Prepare the test app before running the generator"
  task :prepare do
    return if Dir.exist?("test/tmp/sample")

    system "cd test/tmp && rails new sample"

    # I don't like testing performance!
    FileUtils.rm_rf("test/tmp/sample/test/performance")

    # Add any gems you need for testing
    # system "echo \"\" >> test/sample/Gemfile"

    # bundle
    gem_root = File.expand_path(File.dirname(__FILE__))
    system "echo \"gem '#{gem_name}', :path => '#{gem_root}'\" >> test/tmp/sample/Gemfile"
    system "cd test/tmp/sample && bundle"

    # Make a thing
    system "cd test/tmp/sample && rails g scaffold thing name:string mood:string"
  end

  # This task is not used unless you need to test the generator with an alternate database
  # such as mysql or postgres. By default the tests utilize sqlite3
  desc "Prepares the application with an alternate database"
  task :database do
    puts "==  Configuring the database =================================================="
    system "cp config/database.yml.example test/tmp/sample/config/database.yml"
    system "cd test/tmp/sample && rake db:migrate:reset"
  end

  desc "Run the #{gem_name} generator"
  task gem_name do
    system "cd test/tmp/sample && rails g #{gem_name}:install && rake db:migrate db:test:prepare"
  end

end

task :default => :test
