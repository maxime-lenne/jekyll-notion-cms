# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Run all tests and linters'
task ci: %i[spec rubocop]

desc 'Build and install gem locally'
task :install_local do
  sh 'gem build jekyll-notion-cms.gemspec'
  sh 'gem install jekyll-notion-cms-*.gem'
end

desc 'Run console with gem loaded'
task :console do
  require 'pry'
  require_relative 'lib/jekyll-notion-cms'
  Pry.start
end
