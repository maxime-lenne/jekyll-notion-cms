# frozen_string_literal: true

require_relative 'lib/jekyll_notion_cms/version'

Gem::Specification.new do |spec|
  spec.name          = 'jekyll-notion-cms'
  spec.version       = JekyllNotionCMS::VERSION
  spec.authors       = ['Maxime Lenne']
  spec.email         = ['hello@maxime-lenne.fr']

  spec.summary       = 'Jekyll plugin to sync content from Notion databases'
  spec.description   = 'A configurable Jekyll plugin that fetches content from Notion databases ' \
                       'and makes it available as Jekyll data files. Supports multiple collections, ' \
                       'various property types, and automatic fallback to Jekyll collections.'
  spec.homepage      = 'https://github.com/maxime-lenne/jekyll-notion-cms'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'documentation_uri' => "#{spec.homepage}#readme",
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) ||
        f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'jekyll', '>= 3.7', '< 5.0'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
