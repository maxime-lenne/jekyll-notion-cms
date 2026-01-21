# frozen_string_literal: true

require 'jekyll'
require_relative 'jekyll_notion_cms/version'
require_relative 'jekyll_notion_cms/notion_client'
require_relative 'jekyll_notion_cms/property_extractors'
require_relative 'jekyll_notion_cms/data_organizers'
require_relative 'jekyll_notion_cms/generator'

module JekyllNotionCMS
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class APIError < Error; end
end
