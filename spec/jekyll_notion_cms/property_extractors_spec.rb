# frozen_string_literal: true

RSpec.describe JekyllNotionCMS::PropertyExtractors do
  describe '.extract' do
    describe 'title property' do
      let(:properties) do
        {
          'Name' => {
            'type' => 'title',
            'title' => [{ 'plain_text' => 'Hello' }, { 'plain_text' => ' World' }]
          }
        }
      end

      it 'extracts concatenated title text' do
        result = described_class.extract(properties, 'Name', 'title')
        expect(result).to eq('Hello World')
      end

      it 'returns nil for missing property' do
        result = described_class.extract(properties, 'Missing', 'title')
        expect(result).to be_nil
      end
    end

    describe 'rich_text property' do
      let(:properties) do
        {
          'Description' => {
            'type' => 'rich_text',
            'rich_text' => [{ 'plain_text' => 'Some text' }]
          }
        }
      end

      it 'extracts rich text' do
        result = described_class.extract(properties, 'Description', 'rich_text')
        expect(result).to eq('Some text')
      end

      it 'returns nil for empty rich text' do
        properties['Description']['rich_text'] = []
        result = described_class.extract(properties, 'Description', 'rich_text')
        expect(result).to be_nil
      end
    end

    describe 'number property' do
      let(:properties) do
        {
          'Level' => { 'type' => 'number', 'number' => 42 }
        }
      end

      it 'extracts number value' do
        result = described_class.extract(properties, 'Level', 'number')
        expect(result).to eq(42)
      end

      context 'with select value conversion' do
        let(:properties) do
          {
            'Level' => { 'type' => 'select', 'select' => { 'name' => 'Expert' } }
          }
        end

        it 'converts Expert to 90' do
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to eq(90)
        end
      end
    end

    describe 'checkbox property' do
      it 'extracts true checkbox' do
        properties = { 'Featured' => { 'type' => 'checkbox', 'checkbox' => true } }
        result = described_class.extract(properties, 'Featured', 'checkbox')
        expect(result).to be true
      end

      it 'extracts false checkbox' do
        properties = { 'Featured' => { 'type' => 'checkbox', 'checkbox' => false } }
        result = described_class.extract(properties, 'Featured', 'checkbox')
        expect(result).to be false
      end
    end

    describe 'date property' do
      let(:properties) do
        {
          'Start Date' => {
            'type' => 'date',
            'date' => { 'start' => '2024-01-15', 'end' => '2024-01-20', 'time_zone' => 'Europe/Paris' }
          }
        }
      end

      it 'extracts date with all fields' do
        result = described_class.extract(properties, 'Start Date', 'date')
        expect(result).to eq({ 'start' => '2024-01-15', 'end' => '2024-01-20', 'time_zone' => 'Europe/Paris' })
      end

      it 'returns nil for null date' do
        properties['Start Date']['date'] = nil
        result = described_class.extract(properties, 'Start Date', 'date')
        expect(result).to be_nil
      end
    end

    describe 'select property' do
      let(:properties) do
        {
          'Status' => { 'type' => 'select', 'select' => { 'name' => 'Published' } }
        }
      end

      it 'extracts select name' do
        result = described_class.extract(properties, 'Status', 'select')
        expect(result).to eq('Published')
      end

      it 'returns nil for null select' do
        properties['Status']['select'] = nil
        result = described_class.extract(properties, 'Status', 'select')
        expect(result).to be_nil
      end
    end

    describe 'multi_select property' do
      let(:properties) do
        {
          'Tags' => {
            'type' => 'multi_select',
            'multi_select' => [{ 'name' => 'Ruby' }, { 'name' => 'Jekyll' }]
          }
        }
      end

      it 'extracts array of names' do
        result = described_class.extract(properties, 'Tags', 'multi_select')
        expect(result).to eq(%w[Ruby Jekyll])
      end

      it 'returns empty array for empty multi_select' do
        properties['Tags']['multi_select'] = []
        result = described_class.extract(properties, 'Tags', 'multi_select')
        expect(result).to eq([])
      end
    end

    describe 'url property' do
      it 'extracts url value' do
        properties = { 'Link' => { 'type' => 'url', 'url' => 'https://example.com' } }
        result = described_class.extract(properties, 'Link', 'url')
        expect(result).to eq('https://example.com')
      end

      it 'extracts url from rich_text' do
        properties = { 'Link' => { 'type' => 'rich_text', 'rich_text' => [{ 'plain_text' => 'https://example.com' }] } }
        result = described_class.extract(properties, 'Link', 'url')
        expect(result).to eq('https://example.com')
      end
    end

    describe 'rollup property' do
      let(:properties) do
        {
          'Category' => {
            'type' => 'rollup',
            'rollup' => {
              'type' => 'array',
              'array' => [{ 'type' => 'title', 'title' => [{ 'plain_text' => 'Backend' }] }]
            }
          }
        }
      end

      it 'extracts first value from rollup array' do
        result = described_class.extract(properties, 'Category', 'rollup')
        expect(result).to eq('Backend')
      end
    end
  end

  describe '.extract_all' do
    let(:properties) do
      {
        'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Test Item' }] },
        'Level' => { 'type' => 'number', 'number' => 85 },
        'Featured' => { 'type' => 'checkbox', 'checkbox' => true }
      }
    end

    let(:config) do
      [
        { 'name' => 'Title', 'type' => 'title' },
        { 'name' => 'Level', 'type' => 'number' },
        { 'name' => 'Featured', 'type' => 'checkbox' }
      ]
    end

    it 'extracts all configured properties' do
      result = described_class.extract_all(properties, config)
      expect(result['title']).to eq('Test Item')
      expect(result['level']).to eq(85)
      expect(result['featured']).to be true
    end

    it 'uses custom key when specified' do
      config[0]['key'] = 'name'
      result = described_class.extract_all(properties, config)
      expect(result['name']).to eq('Test Item')
    end
  end

  describe '.normalize_key' do
    it 'converts to lowercase' do
      expect(described_class.normalize_key('Title')).to eq('title')
    end

    it 'replaces spaces with underscores' do
      expect(described_class.normalize_key('Start Date')).to eq('start_date')
    end

    it 'handles multiple spaces' do
      expect(described_class.normalize_key('Some  Long  Name')).to eq('some_long_name')
    end
  end
end
