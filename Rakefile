require "bundler/gem_tasks"
require 'rake/testtask'

gem_name = :authkit

Rake::TestTask.new(:test => ["generator:cleanup", "generator:prepare", "generator:#{gem_name}"]) do |task|
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
    FileUtils.rm_rf("test/rails")
  end

  desc "Prepare the test app before running the generator"
  task :prepare do
    system "cd test && rails rails"

    # I don't like testing performance!
    FileUtils.rm_rf("test/rails/test/performance")

    # Add any gems you need for testing
    # system "echo \"\" >> test/rails/Gemfile"

    # bundle
    system "cd test/rails && bundle"

    # Make a thing
    system "cd test/rails && rails g scaffold thing name:string mood:string"

    FileUtils.mkdir_p("test/rails/vendor/plugins")
    gem_root = File.expand_path(File.dirname(__FILE__))
    system("ln -s #{gem_root} test/rails/vendor/plugins/#{gem_name}")
  end

  desc "Prepares the application with an alternate database"
  task :database do
    puts "==  Configuring the database =================================================="
    system "cp config/database.yml.example test/rails/config/database.yml"
    system "cd test/rails && rake db:migrate:reset"
  end

  desc "Run the #{gem_name} generator"
  task gem_name do
    system "cd test/rails && rails g #{gem_name} && rake db:migrate db:test:prepare"
  end

end

task :default => :test
