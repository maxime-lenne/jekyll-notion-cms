# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 50
end

require 'bundler/setup'
require 'jekyll-notion-cms'
require 'webmock/rspec'

# Disable external connections
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    # Reset environment variables
    ENV.delete('NOTION_TOKEN')
    ENV.delete('NOTION_TEST_DB')
  end
end

# Helper to load fixture files
def fixture_path(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end

def load_fixture(filename)
  JSON.parse(File.read(fixture_path(filename)))
end
