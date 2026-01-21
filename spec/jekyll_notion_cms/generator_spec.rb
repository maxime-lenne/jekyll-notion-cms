# frozen_string_literal: true

RSpec.describe JekyllNotionCMS::Generator do
  let(:site) { instance_double(Jekyll::Site) }
  let(:source_dir) { '/tmp/jekyll_test_site' }
  let(:data_dir) { File.join(source_dir, '_data') }
  let(:generator) { described_class.new }

  before do
    allow(site).to receive(:source).and_return(source_dir)
    allow(site).to receive(:data).and_return({})
    allow(site).to receive(:config).and_return({})
    allow(site).to receive(:collections).and_return({})
    allow(Jekyll.logger).to receive(:info)
    allow(Jekyll.logger).to receive(:warn)
    allow(Jekyll.logger).to receive(:error)
    FileUtils.rm_rf(data_dir)
  end

  after do
    FileUtils.rm_rf(data_dir)
  end

  describe '#generate' do
    context 'when plugin is disabled' do
      before do
        allow(site).to receive(:config).and_return({ 'notion' => { 'enabled' => false } })
      end

      it 'logs that the plugin is disabled' do
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'Plugin disabled in configuration')
        generator.generate(site)
      end

      it 'does not fetch data' do
        expect(JekyllNotionCMS::NotionClient).not_to receive(:new)
        generator.generate(site)
      end
    end

    context 'when NOTION_TOKEN is missing' do
      let(:config) do
        {
          'notion' => {
            'collections' => {
              'posts' => { 'database_env' => 'POSTS_DB', 'data_file' => 'posts.yml', 'properties' => [] }
            }
          }
        }
      end

      before do
        allow(site).to receive(:config).and_return(config)
        ENV.delete('NOTION_TOKEN')
      end

      it 'logs that no token was found' do
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'No NOTION_TOKEN found, using collections fallback')
        generator.generate(site)
      end

      it 'uses fallback for all collections' do
        FileUtils.mkdir_p(data_dir)
        generator.generate(site)
        expect(File.exist?(File.join(data_dir, 'posts.yml'))).to be true
      end
    end

    context 'when NOTION_TOKEN exists' do
      let(:notion_client) { instance_double(JekyllNotionCMS::NotionClient) }
      let(:notion_response) do
        {
          'results' => [
            {
              'id' => 'page-1',
              'properties' => {
                'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Test Post' }] }
              },
              'created_time' => '2024-01-01T00:00:00Z',
              'last_edited_time' => '2024-01-02T00:00:00Z'
            }
          ]
        }
      end
      let(:config) do
        {
          'notion' => {
            'collections' => {
              'posts' => {
                'database_env' => 'POSTS_DB',
                'data_file' => 'posts.yml',
                'properties' => [{ 'name' => 'Title', 'type' => 'title' }]
              }
            }
          }
        }
      end

      before do
        ENV['NOTION_TOKEN'] = 'test_token'
        ENV['POSTS_DB'] = 'db_123'
        allow(site).to receive(:config).and_return(config)
        allow(JekyllNotionCMS::NotionClient).to receive(:new).with('test_token').and_return(notion_client)
        allow(notion_client).to receive(:query_database).with('db_123').and_return(notion_response)
      end

      after do
        ENV.delete('NOTION_TOKEN')
        ENV.delete('POSTS_DB')
      end

      it 'creates a NotionClient' do
        expect(JekyllNotionCMS::NotionClient).to receive(:new).with('test_token')
        generator.generate(site)
      end

      it 'fetches data from each configured collection' do
        expect(notion_client).to receive(:query_database).with('db_123')
        generator.generate(site)
      end

      it 'logs success message' do
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'All data fetched successfully')
        generator.generate(site)
      end

      it 'writes data to site.data' do
        generator.generate(site)
        expect(site.data['posts']).to be_an(Array)
      end

      it 'creates data file' do
        FileUtils.mkdir_p(data_dir)
        generator.generate(site)
        expect(File.exist?(File.join(data_dir, 'posts.yml'))).to be true
      end
    end

    context 'when API error occurs during collection fetch' do
      let(:notion_client) { instance_double(JekyllNotionCMS::NotionClient) }
      let(:config) do
        {
          'notion' => {
            'collections' => {
              'posts' => {
                'database_env' => 'POSTS_DB',
                'data_file' => 'posts.yml',
                'properties' => []
              }
            }
          }
        }
      end

      before do
        ENV['NOTION_TOKEN'] = 'test_token'
        ENV['POSTS_DB'] = 'db_123'
        FileUtils.mkdir_p(data_dir)
        allow(site).to receive(:config).and_return(config)
        allow(JekyllNotionCMS::NotionClient).to receive(:new).and_return(notion_client)
        allow(notion_client).to receive(:query_database).and_raise(StandardError, 'API Error')
      end

      after do
        ENV.delete('NOTION_TOKEN')
        ENV.delete('POSTS_DB')
      end

      it 'logs the error per collection' do
        expect(Jekyll.logger).to receive(:error).with('NotionCMS:', 'Error fetching posts: API Error')
        generator.generate(site)
      end

      it 'uses collection fallback' do
        generator.generate(site)
        expect(site.data['posts']).to eq([])
      end
    end

    context 'when client initialization fails' do
      let(:config) do
        {
          'notion' => {
            'collections' => {
              'posts' => {
                'database_env' => 'POSTS_DB',
                'data_file' => 'posts.yml',
                'properties' => []
              }
            }
          }
        }
      end

      before do
        ENV['NOTION_TOKEN'] = 'test_token'
        FileUtils.mkdir_p(data_dir)
        allow(site).to receive(:config).and_return(config)
        allow(JekyllNotionCMS::NotionClient).to receive(:new).and_raise(StandardError, 'Connection failed')
      end

      after do
        ENV.delete('NOTION_TOKEN')
      end

      it 'logs the error' do
        expect(Jekyll.logger).to receive(:error).with('NotionCMS:', 'Error fetching data: Connection failed')
        generator.generate(site)
      end

      it 'falls back to all collections' do
        expect(Jekyll.logger).to receive(:warn).with('NotionCMS:', 'Falling back to collections')
        generator.generate(site)
      end
    end
  end

  describe '#fetch_collection_data' do
    let(:notion_client) { instance_double(JekyllNotionCMS::NotionClient) }
    let(:config) do
      {
        'database_env' => 'TEST_DB',
        'data_file' => 'test.yml',
        'properties' => [{ 'name' => 'Title', 'type' => 'title' }]
      }
    end
    let(:notion_response) do
      {
        'results' => [
          {
            'id' => 'page-1',
            'properties' => {
              'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Test' }] }
            },
            'created_time' => '2024-01-01T00:00:00Z',
            'last_edited_time' => '2024-01-02T00:00:00Z'
          }
        ]
      }
    end

    before do
      ENV['NOTION_TOKEN'] = 'test_token'
      allow(site).to receive(:config).and_return({ 'notion' => { 'collections' => {} } })
      allow(JekyllNotionCMS::NotionClient).to receive(:new).and_return(notion_client)
    end

    after do
      ENV.delete('NOTION_TOKEN')
      ENV.delete('TEST_DB')
    end

    context 'when database_id is missing' do
      it 'uses fallback' do
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'No TEST_DB found, using fallback for test_collection')
        generator.generate(site)
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when database_id starts with example_' do
      before do
        ENV['TEST_DB'] = 'example_db_123'
      end

      it 'uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'No TEST_DB found, using fallback for test_collection')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when database_id is empty' do
      before do
        ENV['TEST_DB'] = ''
      end

      it 'uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'No TEST_DB found, using fallback for test_collection')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when API returns empty results' do
      before do
        ENV['TEST_DB'] = 'db_123'
        allow(notion_client).to receive(:query_database).and_return({ 'results' => [] })
      end

      it 'uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:warn).with('NotionCMS:', 'No data found for test_collection, using fallback')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when API call fails' do
      before do
        ENV['TEST_DB'] = 'db_123'
        allow(notion_client).to receive(:query_database).and_raise(StandardError, 'Connection error')
      end

      it 'logs error and uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:error).with('NotionCMS:', 'Error fetching test_collection: Connection error')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when organized data is a hash' do
      let(:config_with_grouping) do
        {
          'database_env' => 'TEST_DB',
          'data_file' => 'test.yml',
          'organizer' => 'grouped_by',
          'group_by' => 'category',
          'properties' => [
            { 'name' => 'Title', 'type' => 'title' },
            { 'name' => 'Category', 'type' => 'select' }
          ]
        }
      end
      let(:grouped_response) do
        {
          'results' => [
            {
              'id' => 'page-1',
              'properties' => {
                'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Test' }] },
                'Category' => { 'type' => 'select', 'select' => { 'name' => 'Tech' } }
              },
              'created_time' => '2024-01-01T00:00:00Z',
              'last_edited_time' => '2024-01-02T00:00:00Z'
            }
          ]
        }
      end

      before do
        ENV['TEST_DB'] = 'db_123'
        allow(notion_client).to receive(:query_database).and_return(grouped_response)
      end

      it 'counts items correctly for hash data' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', match(/test_collection fetched \(\d+ items\)/))
        generator.send(:fetch_collection_data, 'test_collection', config_with_grouping)
      end
    end
  end

  describe '#create_data_file' do
    let(:data) { [{ 'title' => 'Test' }] }
    let(:file_name) { 'test.yml' }
    let(:collection_name) { 'test' }

    before do
      FileUtils.mkdir_p(data_dir)
      allow(site).to receive(:config).and_return({ 'notion' => { 'collections' => {} } })
      generator.generate(site)
    end

    it 'creates the _data directory if it does not exist' do
      FileUtils.rm_rf(data_dir)
      generator.send(:create_data_file, data, file_name, collection_name)
      expect(Dir.exist?(data_dir)).to be true
    end

    it 'writes data to file' do
      generator.send(:create_data_file, data, file_name, collection_name)
      expect(File.exist?(File.join(data_dir, file_name))).to be true
    end

    it 'includes header comments' do
      generator.send(:create_data_file, data, file_name, collection_name)
      content = File.read(File.join(data_dir, file_name))
      expect(content).to include('# Test data imported from Notion')
      expect(content).to include('# Auto-generated by jekyll-notion-cms')
      expect(content).to include('# Last updated:')
    end

    it 'includes YAML data' do
      generator.send(:create_data_file, data, file_name, collection_name)
      content = File.read(File.join(data_dir, file_name))
      expect(content).to include('title: Test')
    end

    context 'when content is unchanged' do
      it 'skips writing' do
        generator.send(:create_data_file, data, file_name, collection_name)
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'test data unchanged, skipping')
        generator.send(:create_data_file, data, file_name, collection_name)
      end
    end

    context 'when content has changed' do
      it 'writes new content' do
        generator.send(:create_data_file, data, file_name, collection_name)
        new_data = [{ 'title' => 'Updated' }]
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', "test written to _data/#{file_name}")
        generator.send(:create_data_file, new_data, file_name, collection_name)
      end
    end
  end

  describe '#use_collection_fallback' do
    let(:config) do
      {
        'data_file' => 'posts.yml',
        'properties' => [
          { 'name' => 'Title', 'type' => 'title' },
          { 'name' => 'Order', 'type' => 'number' }
        ]
      }
    end

    before do
      FileUtils.mkdir_p(data_dir)
      allow(site).to receive(:config).and_return({ 'notion' => { 'collections' => {} } })
      generator.generate(site)
    end

    context 'when Jekyll collection exists' do
      let(:doc1) do
        instance_double(
          Jekyll::Document,
          data: { 'title' => 'Post 1', 'order' => 1, 'date' => Date.new(2024, 1, 1), 'last_modified' => Date.new(2024, 1, 2) }
        )
      end
      let(:doc2) do
        instance_double(
          Jekyll::Document,
          data: { 'title' => 'Post 2', 'order' => 2 }
        )
      end
      let(:collection) { instance_double(Jekyll::Collection, docs: [doc1, doc2]) }

      before do
        allow(site).to receive(:collections).and_return({ 'posts' => collection })
      end

      it 'converts Jekyll docs to Notion format' do
        generator.send(:use_collection_fallback, 'posts', config)
        expect(site.data['posts']).to be_an(Array)
      end

      it 'includes document data' do
        generator.send(:use_collection_fallback, 'posts', config)
        expect(site.data['posts'].length).to eq(2)
      end

      it 'logs the fallback count' do
        expect(Jekyll.logger).to receive(:info).with('NotionCMS:', 'posts fallback applied (2 items)')
        generator.send(:use_collection_fallback, 'posts', config)
      end
    end

    context 'when Jekyll collection does not exist' do
      it 'creates empty data' do
        generator.send(:use_collection_fallback, 'nonexistent', config)
        expect(site.data['posts']).to eq([])
      end
    end

    context 'with .yaml extension' do
      let(:yaml_config) do
        {
          'data_file' => 'posts.yaml',
          'properties' => []
        }
      end

      it 'handles .yaml extension correctly' do
        generator.send(:use_collection_fallback, 'posts', yaml_config)
        expect(site.data['posts']).to eq([])
      end
    end
  end

  describe '#convert_doc_to_properties' do
    let(:properties_config) do
      [
        { 'name' => 'Title', 'type' => 'title' },
        { 'name' => 'Description', 'type' => 'rich_text', 'key' => 'desc' },
        { 'name' => 'Order', 'type' => 'number' }
      ]
    end

    before do
      allow(site).to receive(:config).and_return({ 'notion' => { 'collections' => {} } })
      generator.generate(site)
    end

    it 'converts document data to Notion properties' do
      data = { 'title' => 'Test', 'desc' => 'Description', 'order' => 1 }
      result = generator.send(:convert_doc_to_properties, data, properties_config)

      expect(result['Title']['type']).to eq('title')
      expect(result['Title']['title'].first['plain_text']).to eq('Test')
    end

    it 'uses custom key when specified' do
      data = { 'desc' => 'Custom description' }
      result = generator.send(:convert_doc_to_properties, data, properties_config)

      expect(result['Description']['rich_text'].first['plain_text']).to eq('Custom description')
    end

    it 'tries lowercase property name as fallback' do
      data = { 'title' => 'Lowercase key' }
      result = generator.send(:convert_doc_to_properties, data, properties_config)

      expect(result['Title']['title'].first['plain_text']).to eq('Lowercase key')
    end

    it 'tries original property name as final fallback' do
      data = { 'Title' => 'Original key' }
      result = generator.send(:convert_doc_to_properties, data, properties_config)

      expect(result['Title']['title'].first['plain_text']).to eq('Original key')
    end

    it 'skips nil values' do
      data = { 'title' => nil }
      result = generator.send(:convert_doc_to_properties, data, properties_config)

      expect(result).not_to have_key('Title')
    end
  end

  describe '#convert_value_to_notion_property' do
    before do
      allow(site).to receive(:config).and_return({ 'notion' => { 'collections' => {} } })
      generator.generate(site)
    end

    it 'converts title type' do
      result = generator.send(:convert_value_to_notion_property, 'Test Title', 'title')
      expect(result['type']).to eq('title')
      expect(result['title'].first['plain_text']).to eq('Test Title')
    end

    it 'converts rich_text type' do
      result = generator.send(:convert_value_to_notion_property, 'Some text', 'rich_text')
      expect(result['type']).to eq('rich_text')
      expect(result['rich_text'].first['plain_text']).to eq('Some text')
    end

    it 'converts number type' do
      result = generator.send(:convert_value_to_notion_property, '42', 'number')
      expect(result['type']).to eq('number')
      expect(result['number']).to eq(42)
    end

    it 'converts checkbox type with true' do
      result = generator.send(:convert_value_to_notion_property, true, 'checkbox')
      expect(result['type']).to eq('checkbox')
      expect(result['checkbox']).to be true
    end

    it 'converts checkbox type with false' do
      result = generator.send(:convert_value_to_notion_property, false, 'checkbox')
      expect(result['checkbox']).to be false
    end

    it 'converts checkbox type with truthy value' do
      result = generator.send(:convert_value_to_notion_property, 'yes', 'checkbox')
      expect(result['checkbox']).to be true
    end

    it 'converts date type' do
      result = generator.send(:convert_value_to_notion_property, '2024-01-01', 'date')
      expect(result['type']).to eq('date')
      expect(result['date']['start']).to eq('2024-01-01')
    end

    it 'converts select type' do
      result = generator.send(:convert_value_to_notion_property, 'Option A', 'select')
      expect(result['type']).to eq('select')
      expect(result['select']['name']).to eq('Option A')
    end

    it 'converts multi_select type with array' do
      result = generator.send(:convert_value_to_notion_property, %w[Tag1 Tag2], 'multi_select')
      expect(result['type']).to eq('multi_select')
      expect(result['multi_select'].length).to eq(2)
      expect(result['multi_select'].first['name']).to eq('Tag1')
    end

    it 'converts multi_select type with single value' do
      result = generator.send(:convert_value_to_notion_property, 'SingleTag', 'multi_select')
      expect(result['multi_select'].length).to eq(1)
      expect(result['multi_select'].first['name']).to eq('SingleTag')
    end

    it 'converts url type' do
      result = generator.send(:convert_value_to_notion_property, 'https://example.com', 'url')
      expect(result['type']).to eq('url')
      expect(result['url']).to eq('https://example.com')
    end

    it 'defaults to rich_text for unknown types' do
      result = generator.send(:convert_value_to_notion_property, 'unknown', 'unknown_type')
      expect(result['type']).to eq('rich_text')
      expect(result['rich_text'].first['plain_text']).to eq('unknown')
    end

    it 'converts non-string values to string' do
      result = generator.send(:convert_value_to_notion_property, 123, 'title')
      expect(result['title'].first['plain_text']).to eq('123')
    end
  end

  describe '#use_all_collections_fallback' do
    let(:config) do
      {
        'notion' => {
          'collections' => {
            'posts' => { 'data_file' => 'posts.yml', 'properties' => [] },
            'projects' => { 'data_file' => 'projects.yml', 'properties' => [] }
          }
        }
      }
    end

    before do
      FileUtils.mkdir_p(data_dir)
      allow(site).to receive(:config).and_return(config)
    end

    it 'applies fallback to all collections' do
      ENV.delete('NOTION_TOKEN')
      generator.generate(site)

      expect(site.data['posts']).to eq([])
      expect(site.data['projects']).to eq([])
    end

    it 'creates data files for all collections' do
      ENV.delete('NOTION_TOKEN')
      generator.generate(site)

      expect(File.exist?(File.join(data_dir, 'posts.yml'))).to be true
      expect(File.exist?(File.join(data_dir, 'projects.yml'))).to be true
    end
  end
end
