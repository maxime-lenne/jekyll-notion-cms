# frozen_string_literal: true

RSpec.describe JekyllNotionCMS do
  it 'has a version number' do
    expect(JekyllNotionCMS::VERSION).not_to be_nil
    expect(JekyllNotionCMS::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  it 'defines error classes' do
    expect(JekyllNotionCMS::Error).to be < StandardError
    expect(JekyllNotionCMS::ConfigurationError).to be < JekyllNotionCMS::Error
    expect(JekyllNotionCMS::APIError).to be < JekyllNotionCMS::Error
  end
end
