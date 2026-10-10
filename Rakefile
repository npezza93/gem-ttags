# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.pattern = "test/**/*_test.rb"
end

task :default do
  require "rubygems/commands/ttags_command"

  Gem::Commands::TtagsCommand.new.execute
end
