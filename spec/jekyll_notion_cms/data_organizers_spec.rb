# frozen_string_literal: true

RSpec.describe JekyllNotionCMS::DataOrganizers do
  let(:notion_data) do
    {
      'results' => [
        {
          'id' => 'page-1',
          'properties' => {
            'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Item A' }] },
            'Order' => { 'type' => 'number', 'number' => 2 }
          },
          'created_time' => '2024-01-01T00:00:00Z',
          'last_edited_time' => '2024-01-02T00:00:00Z'
        },
        {
          'id' => 'page-2',
          'properties' => {
            'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Item B' }] },
            'Order' => { 'type' => 'number', 'number' => 1 }
          },
          'created_time' => '2024-01-01T00:00:00Z',
          'last_edited_time' => '2024-01-02T00:00:00Z'
        }
      ]
    }
  end

  let(:properties_config) do
    [
      { 'name' => 'Title', 'type' => 'title' },
      { 'name' => 'Order', 'type' => 'number' }
    ]
  end

  describe '.organize' do
    it 'defaults to simple_list organizer' do
      config = { 'properties' => properties_config }
      result = described_class.organize(notion_data, config)
      expect(result).to be_an(Array)
    end

    it 'uses specified organizer' do
      config = { 'organizer' => 'simple_list', 'properties' => properties_config }
      result = described_class.organize(notion_data, config)
      expect(result).to be_an(Array)
    end
  end

  describe '.organize_simple_list' do
    it 'returns an array of items' do
      result = described_class.organize_simple_list(notion_data, properties_config, nil, 'asc')
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'includes id and timestamps' do
      result = described_class.organize_simple_list(notion_data, properties_config, nil, 'asc')
      expect(result.first['id']).to eq('page-1')
      expect(result.first['created_time']).not_to be_nil
    end

    it 'sorts by specified field ascending' do
      result = described_class.organize_simple_list(notion_data, properties_config, 'order', 'asc')
      expect(result.first['title']).to eq('Item B')
      expect(result.last['title']).to eq('Item A')
    end

    it 'sorts by specified field descending' do
      result = described_class.organize_simple_list(notion_data, properties_config, 'order', 'desc')
      expect(result.first['title']).to eq('Item A')
      expect(result.last['title']).to eq('Item B')
    end

    it 'filters out items without title' do
      notion_data['results'] << {
        'id' => 'page-3',
        'properties' => {
          'Title' => { 'type' => 'title', 'title' => [] },
          'Order' => { 'type' => 'number', 'number' => 3 }
        }
      }
      result = described_class.organize_simple_list(notion_data, properties_config, nil, 'asc')
      expect(result.length).to eq(2)
    end
  end

  describe '.organize_items_by_category' do
    let(:items_data) do
      {
        'results' => [
          {
            'id' => 'item-1',
            'properties' => {
              'Name' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Ruby' }] },
              'Level' => { 'type' => 'number', 'number' => 90 },
              'Category' => { 'type' => 'rollup', 'rollup' => { 'type' => 'array', 'array' => [{ 'type' => 'title', 'title' => [{ 'plain_text' => 'Backend' }] }] } },
              'Order' => { 'type' => 'number', 'number' => 1 }
            }
          },
          {
            'id' => 'item-2',
            'properties' => {
              'Name' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Python' }] },
              'Level' => { 'type' => 'number', 'number' => 85 },
              'Category' => { 'type' => 'rollup', 'rollup' => { 'type' => 'array', 'array' => [{ 'type' => 'title', 'title' => [{ 'plain_text' => 'Backend' }] }] } },
              'Order' => { 'type' => 'number', 'number' => 2 }
            }
          },
          {
            'id' => 'item-3',
            'properties' => {
              'Name' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'React' }] },
              'Level' => { 'type' => 'number', 'number' => 80 },
              'Category' => { 'type' => 'rollup', 'rollup' => { 'type' => 'array', 'array' => [{ 'type' => 'title', 'title' => [{ 'plain_text' => 'Frontend' }] }] } },
              'Order' => { 'type' => 'number', 'number' => 1 }
            }
          }
        ]
      }
    end

    it 'groups items by category' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result.keys).to contain_exactly('Backend', 'Frontend')
    end

    it 'includes category metadata' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result['Backend']['title']).to eq('Backend')
      expect(result['Backend']['category']).to eq('Backend')
    end

    it 'includes items in each category' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result['Backend']['items'].length).to eq(2)
      expect(result['Frontend']['items'].length).to eq(1)
    end

    it 'sorts items within categories by order' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result['Backend']['items'].first['name']).to eq('Ruby')
    end
  end

  describe '.organize_grouped_by' do
    let(:grouped_data) do
      {
        'results' => [
          {
            'id' => 'item-1',
            'properties' => {
              'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Post A' }] },
              'Category' => { 'type' => 'select', 'select' => { 'name' => 'Tech' } },
              'Order' => { 'type' => 'number', 'number' => 1 }
            }
          },
          {
            'id' => 'item-2',
            'properties' => {
              'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Post B' }] },
              'Category' => { 'type' => 'select', 'select' => { 'name' => 'Tech' } },
              'Order' => { 'type' => 'number', 'number' => 2 }
            }
          },
          {
            'id' => 'item-3',
            'properties' => {
              'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Post C' }] },
              'Category' => { 'type' => 'select', 'select' => { 'name' => 'Design' } },
              'Order' => { 'type' => 'number', 'number' => 1 }
            }
          }
        ]
      }
    end

    let(:grouped_config) do
      [
        { 'name' => 'Title', 'type' => 'title' },
        { 'name' => 'Category', 'type' => 'select' },
        { 'name' => 'Order', 'type' => 'number' }
      ]
    end

    it 'groups items by specified field' do
      result = described_class.organize_grouped_by(grouped_data, grouped_config, 'category', 'order', 'asc')
      expect(result.keys).to contain_exactly('Tech', 'Design')
    end

    it 'includes correct items in each group' do
      result = described_class.organize_grouped_by(grouped_data, grouped_config, 'category', 'order', 'asc')
      expect(result['Tech'].length).to eq(2)
      expect(result['Design'].length).to eq(1)
    end
  end

  describe '.data_present?' do
    it 'returns false for nil' do
      expect(described_class.data_present?(nil)).to be false
    end

    it 'returns false for empty array' do
      expect(described_class.data_present?([])).to be false
    end

    it 'returns false for empty hash' do
      expect(described_class.data_present?({})).to be false
    end

    it 'returns true for non-empty array' do
      expect(described_class.data_present?([1])).to be true
    end

    it 'returns true for non-empty hash' do
      expect(described_class.data_present?({ a: 1 })).to be true
    end
  end
end
