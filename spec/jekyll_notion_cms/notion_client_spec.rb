# frozen_string_literal: true

RSpec.describe JekyllNotionCMS::NotionClient do
  let(:token) { 'secret_test_token' }
  let(:client) { described_class.new(token) }
  let(:database_id) { 'test-database-id' }

  describe '#initialize' do
    it 'creates a client with a valid token' do
      expect { described_class.new(token) }.not_to raise_error
    end

    it 'raises an error with nil token' do
      expect { described_class.new(nil) }.to raise_error(JekyllNotionCMS::ConfigurationError)
    end

    it 'raises an error with empty token' do
      expect { described_class.new('') }.to raise_error(JekyllNotionCMS::ConfigurationError)
    end
  end

  describe '#query_database' do
    let(:api_response) do
      {
        'results' => [
          { 'id' => 'page-1', 'properties' => {} },
          { 'id' => 'page-2', 'properties' => {} }
        ],
        'has_more' => false,
        'next_cursor' => nil
      }
    end

    before do
      stub_request(:post, "https://api.notion.com/v1/databases/#{database_id}/query")
        .with(
          headers: {
            'Authorization' => "Bearer #{token}",
            'Notion-Version' => '2022-06-28',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: api_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns results from the database' do
      result = client.query_database(database_id)
      expect(result['results'].length).to eq(2)
    end

    it 'includes all pages' do
      result = client.query_database(database_id)
      expect(result['results'].map { |r| r['id'] }).to eq(%w[page-1 page-2])
    end

    context 'with pagination' do
      let(:page1_response) do
        {
          'results' => [{ 'id' => 'page-1', 'properties' => {} }],
          'has_more' => true,
          'next_cursor' => 'cursor-123'
        }
      end

      let(:page2_response) do
        {
          'results' => [{ 'id' => 'page-2', 'properties' => {} }],
          'has_more' => false,
          'next_cursor' => nil
        }
      end

      before do
        stub_request(:post, "https://api.notion.com/v1/databases/#{database_id}/query")
          .with(body: hash_including('page_size' => 100))
          .to_return(status: 200, body: page1_response.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, "https://api.notion.com/v1/databases/#{database_id}/query")
          .with(body: hash_including('start_cursor' => 'cursor-123'))
          .to_return(status: 200, body: page2_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'fetches all pages automatically' do
        result = client.query_database(database_id)
        expect(result['results'].length).to eq(2)
      end
    end

    context 'with API errors' do
      it 'raises APIError for 401 Unauthorized' do
        stub_request(:post, "https://api.notion.com/v1/databases/#{database_id}/query")
          .to_return(status: 401, body: { 'message' => 'Invalid token' }.to_json)

        expect { client.query_database(database_id) }
          .to raise_error(JekyllNotionCMS::APIError, /401 Unauthorized/)
      end

      it 'raises APIError for 404 Not Found' do
        stub_request(:post, "https://api.notion.com/v1/databases/#{database_id}/query")
          .to_return(status: 404, body: { 'message' => 'Database not found' }.to_json)

        expect { client.query_database(database_id) }
          .to raise_error(JekyllNotionCMS::APIError, /404 Not Found/)
      end

      it 'raises APIError for 429 Rate Limited' do
        stub_request(:post, "https://api.notion.com/v1/databases/#{database_id}/query")
          .to_return(status: 429, body: { 'message' => 'Rate limited' }.to_json)

        expect { client.query_database(database_id) }
          .to raise_error(JekyllNotionCMS::APIError, /429 Too Many Requests/)
      end
    end
  end

  describe '#get_page' do
    let(:page_id) { 'test-page-id' }
    let(:page_response) do
      {
        'id' => page_id,
        'properties' => { 'Name' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Test' }] } }
      }
    end

    before do
      stub_request(:get, "https://api.notion.com/v1/pages/#{page_id}")
        .to_return(status: 200, body: page_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the page data' do
      result = client.get_page(page_id)
      expect(result['id']).to eq(page_id)
    end
  end
end
