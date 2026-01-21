# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module JekyllNotionCMS
  # Client for interacting with the Notion API
  class NotionClient
    NOTION_API_VERSION = '2022-06-28'
    NOTION_API_BASE_URL = 'https://api.notion.com/v1'

    def initialize(token)
      @token = token
      raise ConfigurationError, 'Notion token is required' if @token.nil? || @token.empty?
    end

    # Query a Notion database and return all results
    # @param database_id [String] The ID of the database to query
    # @param filter [Hash] Optional filter for the query
    # @param sorts [Array] Optional sorts for the query
    # @return [Hash] The API response with results
    def query_database(database_id, filter: nil, sorts: nil)
      all_results = []
      start_cursor = nil

      loop do
        response = query_database_page(database_id, filter: filter, sorts: sorts, start_cursor: start_cursor)
        all_results.concat(response['results'])

        break unless response['has_more']

        start_cursor = response['next_cursor']
      end

      { 'results' => all_results }
    end

    # Retrieve a single page
    # @param page_id [String] The ID of the page to retrieve
    # @return [Hash] The page data
    def get_page(page_id)
      uri = URI("#{NOTION_API_BASE_URL}/pages/#{page_id}")
      request = build_request(:get, uri)
      execute_request(uri, request)
    end

    # Retrieve page content (blocks)
    # @param page_id [String] The ID of the page
    # @return [Hash] The blocks data
    def get_page_content(page_id)
      all_results = []
      start_cursor = nil

      loop do
        uri = URI("#{NOTION_API_BASE_URL}/blocks/#{page_id}/children")
        uri.query = URI.encode_www_form({ start_cursor: start_cursor, page_size: 100 }.compact)

        request = build_request(:get, uri)
        response = execute_request(uri, request)

        all_results.concat(response['results'])

        break unless response['has_more']

        start_cursor = response['next_cursor']
      end

      { 'results' => all_results }
    end

    private

    def query_database_page(database_id, filter: nil, sorts: nil, start_cursor: nil)
      uri = URI("#{NOTION_API_BASE_URL}/databases/#{database_id}/query")

      body = { page_size: 100 }
      body[:filter] = filter if filter
      body[:sorts] = sorts if sorts
      body[:start_cursor] = start_cursor if start_cursor

      request = build_request(:post, uri)
      request.body = body.to_json

      execute_request(uri, request)
    end

    def build_request(method, uri)
      request_class = case method
                      when :get then Net::HTTP::Get
                      when :post then Net::HTTP::Post
                      else raise ArgumentError, "Unknown method: #{method}"
                      end

      request = request_class.new(uri)
      request['Authorization'] = "Bearer #{@token}"
      request['Notion-Version'] = NOTION_API_VERSION
      request['Content-Type'] = 'application/json'
      request
    end

    def execute_request(uri, request)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      handle_response(response)
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPUnauthorized
        raise APIError, 'Invalid Notion token (401 Unauthorized)'
      when Net::HTTPNotFound
        raise APIError, 'Database or page not found (404 Not Found)'
      when Net::HTTPTooManyRequests
        raise APIError, 'Rate limit exceeded (429 Too Many Requests)'
      else
        error_message = parse_error_message(response)
        raise APIError, "Notion API error: #{response.code} #{error_message}"
      end
    end

    def parse_error_message(response)
      error_json = JSON.parse(response.body)
      error_json['message'] || response.message
    rescue JSON::ParserError
      response.message
    end
  end
end
