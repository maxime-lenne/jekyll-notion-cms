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

      it 'returns nil for wrong type' do
        properties = { 'Name' => { 'type' => 'text', 'text' => 'Hello' } }
        result = described_class.extract(properties, 'Name', 'title')
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

      it 'returns nil for wrong type' do
        properties = { 'Description' => { 'type' => 'text', 'text' => 'Some text' } }
        result = described_class.extract(properties, 'Description', 'rich_text')
        expect(result).to be_nil
      end

      it 'returns nil for nil rich_text' do
        properties = { 'Description' => { 'type' => 'rich_text', 'rich_text' => nil } }
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

        it 'converts Avancé to 90' do
          properties['Level']['select']['name'] = 'Avancé'
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to eq(90)
        end

        it 'converts Advanced to 90' do
          properties['Level']['select']['name'] = 'Advanced'
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to eq(90)
        end

        it 'converts Intermédiaire to 70' do
          properties['Level']['select']['name'] = 'Intermédiaire'
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to eq(70)
        end

        it 'converts Intermediate to 70' do
          properties['Level']['select']['name'] = 'Intermediate'
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to eq(70)
        end

        it 'converts Débutant to 50' do
          properties['Level']['select']['name'] = 'Débutant'
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to eq(50)
        end

        it 'converts Beginner to 50' do
          properties['Level']['select']['name'] = 'Beginner'
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to eq(50)
        end

        it 'returns nil for unknown select value' do
          properties['Level']['select']['name'] = 'Unknown Level'
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to be_nil
        end

        it 'returns nil for null select' do
          properties['Level']['select'] = nil
          result = described_class.extract(properties, 'Level', 'number')
          expect(result).to be_nil
        end
      end

      it 'returns nil for wrong type' do
        properties = { 'Level' => { 'type' => 'text', 'text' => '42' } }
        result = described_class.extract(properties, 'Level', 'number')
        expect(result).to be_nil
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

      it 'returns false for wrong type' do
        properties = { 'Featured' => { 'type' => 'text', 'text' => 'yes' } }
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

      it 'returns nil for wrong type' do
        properties = { 'Start Date' => { 'type' => 'text', 'text' => '2024-01-15' } }
        result = described_class.extract(properties, 'Start Date', 'date')
        expect(result).to be_nil
      end

      it 'compacts nil fields from date' do
        properties = {
          'Start Date' => {
            'type' => 'date',
            'date' => { 'start' => '2024-01-15', 'end' => nil, 'time_zone' => nil }
          }
        }
        result = described_class.extract(properties, 'Start Date', 'date')
        expect(result).to eq({ 'start' => '2024-01-15' })
        expect(result.keys).not_to include('end', 'time_zone')
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

      it 'returns nil for wrong type' do
        properties = { 'Status' => { 'type' => 'text', 'text' => 'Published' } }
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

      it 'returns empty array for wrong type' do
        properties = { 'Tags' => { 'type' => 'text', 'text' => 'Ruby, Jekyll' } }
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

      it 'returns nil for unknown type' do
        properties = { 'Link' => { 'type' => 'unknown', 'unknown' => 'value' } }
        result = described_class.extract(properties, 'Link', 'url')
        expect(result).to be_nil
      end
    end

    describe 'email property' do
      it 'extracts email value' do
        properties = { 'Email' => { 'type' => 'email', 'email' => 'test@example.com' } }
        result = described_class.extract(properties, 'Email', 'email')
        expect(result).to eq('test@example.com')
      end

      it 'returns nil for wrong type' do
        properties = { 'Email' => { 'type' => 'text', 'text' => 'test@example.com' } }
        result = described_class.extract(properties, 'Email', 'email')
        expect(result).to be_nil
      end

      it 'returns nil for null email' do
        properties = { 'Email' => { 'type' => 'email', 'email' => nil } }
        result = described_class.extract(properties, 'Email', 'email')
        expect(result).to be_nil
      end
    end

    describe 'phone_number property' do
      it 'extracts phone number value' do
        properties = { 'Phone' => { 'type' => 'phone_number', 'phone_number' => '+33612345678' } }
        result = described_class.extract(properties, 'Phone', 'phone_number')
        expect(result).to eq('+33612345678')
      end

      it 'returns nil for wrong type' do
        properties = { 'Phone' => { 'type' => 'text', 'text' => '+33612345678' } }
        result = described_class.extract(properties, 'Phone', 'phone_number')
        expect(result).to be_nil
      end
    end

    describe 'formula property' do
      it 'extracts string formula' do
        properties = { 'Computed' => { 'type' => 'formula',
                                       'formula' => { 'type' => 'string', 'string' => 'result' } } }
        result = described_class.extract(properties, 'Computed', 'formula')
        expect(result).to eq('result')
      end

      it 'extracts number formula' do
        properties = { 'Computed' => { 'type' => 'formula', 'formula' => { 'type' => 'number', 'number' => 42 } } }
        result = described_class.extract(properties, 'Computed', 'formula')
        expect(result).to eq(42)
      end

      it 'extracts boolean formula' do
        properties = { 'Computed' => { 'type' => 'formula', 'formula' => { 'type' => 'boolean', 'boolean' => true } } }
        result = described_class.extract(properties, 'Computed', 'formula')
        expect(result).to be true
      end

      it 'extracts date formula' do
        properties = { 'Computed' => { 'type' => 'formula',
                                       'formula' => { 'type' => 'date', 'date' => { 'start' => '2024-01-15' } } } }
        result = described_class.extract(properties, 'Computed', 'formula')
        expect(result).to eq('2024-01-15')
      end

      it 'returns nil for null date formula' do
        properties = { 'Computed' => { 'type' => 'formula', 'formula' => { 'type' => 'date', 'date' => nil } } }
        result = described_class.extract(properties, 'Computed', 'formula')
        expect(result).to be_nil
      end

      it 'returns nil for unknown formula type' do
        properties = { 'Computed' => { 'type' => 'formula',
                                       'formula' => { 'type' => 'unknown', 'unknown' => 'value' } } }
        result = described_class.extract(properties, 'Computed', 'formula')
        expect(result).to be_nil
      end

      it 'returns nil for null formula' do
        properties = { 'Computed' => { 'type' => 'formula', 'formula' => nil } }
        result = described_class.extract(properties, 'Computed', 'formula')
        expect(result).to be_nil
      end
    end

    describe 'formula_array property' do
      it 'extracts array formula with string items' do
        properties = {
          'Tags' => {
            'type' => 'formula',
            'formula' => {
              'type' => 'array',
              'array' => [
                { 'type' => 'string', 'string' => 'tag1' },
                { 'type' => 'string', 'string' => 'tag2' }
              ]
            }
          }
        }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq(%w[tag1 tag2])
      end

      it 'extracts array formula with rich_text items' do
        properties = {
          'Tags' => {
            'type' => 'formula',
            'formula' => {
              'type' => 'array',
              'array' => [
                { 'type' => 'rich_text', 'rich_text' => [{ 'plain_text' => 'item1' }] }
              ]
            }
          }
        }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq(['item1'])
      end

      it 'filters nil items from array' do
        properties = {
          'Tags' => {
            'type' => 'formula',
            'formula' => {
              'type' => 'array',
              'array' => [
                { 'type' => 'string', 'string' => 'tag1' },
                { 'type' => 'unknown', 'unknown' => 'ignored' }
              ]
            }
          }
        }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq(['tag1'])
      end

      it 'parses string formula as array by delimiter' do
        properties = {
          'Tags' => {
            'type' => 'formula',
            'formula' => { 'type' => 'string', 'string' => '- item1- item2- item3' }
          }
        }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq(%w[item1 item2 item3])
      end

      it 'cleans leading and trailing dots from parsed items' do
        properties = {
          'Tags' => {
            'type' => 'formula',
            'formula' => { 'type' => 'string', 'string' => '- ...item1...- ..item2..- item3' }
          }
        }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq(%w[item1 item2 item3])
      end

      it 'filters out empty items after cleaning' do
        properties = {
          'Tags' => {
            'type' => 'formula',
            'formula' => { 'type' => 'string', 'string' => '- ...- item1- - item2' }
          }
        }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq(%w[item1 item2])
      end

      it 'returns empty array for null formula' do
        properties = { 'Tags' => { 'type' => 'formula', 'formula' => nil } }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq([])
      end

      it 'returns empty array for unknown formula type' do
        properties = { 'Tags' => { 'type' => 'formula', 'formula' => { 'type' => 'number', 'number' => 42 } } }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq([])
      end

      it 'returns empty array for wrong property type' do
        properties = { 'Tags' => { 'type' => 'text', 'text' => 'value' } }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq([])
      end

      it 'handles nil array in formula' do
        properties = { 'Tags' => { 'type' => 'formula', 'formula' => { 'type' => 'array', 'array' => nil } } }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq([])
      end

      it 'handles nil rich_text in array item' do
        properties = {
          'Tags' => {
            'type' => 'formula',
            'formula' => {
              'type' => 'array',
              'array' => [{ 'type' => 'rich_text', 'rich_text' => nil }]
            }
          }
        }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq([])
      end

      it 'handles empty string formula' do
        properties = { 'Tags' => { 'type' => 'formula', 'formula' => { 'type' => 'string', 'string' => '' } } }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq([])
      end

      it 'handles nil string formula' do
        properties = { 'Tags' => { 'type' => 'formula', 'formula' => { 'type' => 'string', 'string' => nil } } }
        result = described_class.extract(properties, 'Tags', 'formula_array')
        expect(result).to eq([])
      end
    end

    describe 'relation property' do
      it 'extracts relation IDs' do
        properties = {
          'Related' => {
            'type' => 'relation',
            'relation' => [
              { 'id' => 'abc-123' },
              { 'id' => 'def-456' }
            ]
          }
        }
        result = described_class.extract(properties, 'Related', 'relation')
        expect(result).to eq(%w[abc-123 def-456])
      end

      it 'returns empty array for empty relation' do
        properties = { 'Related' => { 'type' => 'relation', 'relation' => [] } }
        result = described_class.extract(properties, 'Related', 'relation')
        expect(result).to eq([])
      end

      it 'returns empty array for null relation' do
        properties = { 'Related' => { 'type' => 'relation', 'relation' => nil } }
        result = described_class.extract(properties, 'Related', 'relation')
        expect(result).to eq([])
      end

      it 'returns empty array for wrong type' do
        properties = { 'Related' => { 'type' => 'text', 'text' => 'value' } }
        result = described_class.extract(properties, 'Related', 'relation')
        expect(result).to eq([])
      end
    end

    describe 'people property' do
      it 'extracts people with full info' do
        properties = {
          'Assignee' => {
            'type' => 'people',
            'people' => [
              {
                'id' => 'user-123',
                'name' => 'John Doe',
                'avatar_url' => 'https://example.com/avatar.png',
                'person' => { 'email' => 'john@example.com' }
              }
            ]
          }
        }
        result = described_class.extract(properties, 'Assignee', 'people')
        expect(result).to eq([
                               {
                                 'id' => 'user-123',
                                 'name' => 'John Doe',
                                 'email' => 'john@example.com',
                                 'avatar_url' => 'https://example.com/avatar.png'
                               }
                             ])
      end

      it 'extracts people with partial info' do
        properties = {
          'Assignee' => {
            'type' => 'people',
            'people' => [{ 'id' => 'user-123', 'name' => 'Jane Doe' }]
          }
        }
        result = described_class.extract(properties, 'Assignee', 'people')
        expect(result).to eq([{ 'id' => 'user-123', 'name' => 'Jane Doe' }])
      end

      it 'returns empty array for empty people' do
        properties = { 'Assignee' => { 'type' => 'people', 'people' => [] } }
        result = described_class.extract(properties, 'Assignee', 'people')
        expect(result).to eq([])
      end

      it 'returns empty array for null people' do
        properties = { 'Assignee' => { 'type' => 'people', 'people' => nil } }
        result = described_class.extract(properties, 'Assignee', 'people')
        expect(result).to eq([])
      end

      it 'returns empty array for wrong type' do
        properties = { 'Assignee' => { 'type' => 'text', 'text' => 'value' } }
        result = described_class.extract(properties, 'Assignee', 'people')
        expect(result).to eq([])
      end
    end

    describe 'files property' do
      it 'extracts internal file URLs' do
        properties = {
          'Attachment' => {
            'type' => 'files',
            'files' => [
              {
                'name' => 'document.pdf',
                'type' => 'file',
                'file' => { 'url' => 'https://notion.so/files/document.pdf' }
              }
            ]
          }
        }
        result = described_class.extract(properties, 'Attachment', 'files')
        expect(result).to eq([
                               {
                                 'name' => 'document.pdf',
                                 'url' => 'https://notion.so/files/document.pdf',
                                 'type' => 'file'
                               }
                             ])
      end

      it 'extracts external file URLs' do
        properties = {
          'Attachment' => {
            'type' => 'files',
            'files' => [
              {
                'name' => 'image.png',
                'type' => 'external',
                'external' => { 'url' => 'https://example.com/image.png' }
              }
            ]
          }
        }
        result = described_class.extract(properties, 'Attachment', 'files')
        expect(result).to eq([
                               {
                                 'name' => 'image.png',
                                 'url' => 'https://example.com/image.png',
                                 'type' => 'external'
                               }
                             ])
      end

      it 'returns empty array for empty files' do
        properties = { 'Attachment' => { 'type' => 'files', 'files' => [] } }
        result = described_class.extract(properties, 'Attachment', 'files')
        expect(result).to eq([])
      end

      it 'returns empty array for null files' do
        properties = { 'Attachment' => { 'type' => 'files', 'files' => nil } }
        result = described_class.extract(properties, 'Attachment', 'files')
        expect(result).to eq([])
      end

      it 'returns empty array for wrong type' do
        properties = { 'Attachment' => { 'type' => 'text', 'text' => 'value' } }
        result = described_class.extract(properties, 'Attachment', 'files')
        expect(result).to eq([])
      end
    end

    describe 'created_time property' do
      it 'extracts created time' do
        properties = { 'Created' => { 'type' => 'created_time', 'created_time' => '2024-01-15T10:30:00.000Z' } }
        result = described_class.extract(properties, 'Created', 'created_time')
        expect(result).to eq('2024-01-15T10:30:00.000Z')
      end

      it 'returns nil for wrong type' do
        properties = { 'Created' => { 'type' => 'text', 'text' => '2024-01-15' } }
        result = described_class.extract(properties, 'Created', 'created_time')
        expect(result).to be_nil
      end
    end

    describe 'last_edited_time property' do
      it 'extracts last edited time' do
        properties = { 'Updated' => { 'type' => 'last_edited_time', 'last_edited_time' => '2024-01-20T15:45:00.000Z' } }
        result = described_class.extract(properties, 'Updated', 'last_edited_time')
        expect(result).to eq('2024-01-20T15:45:00.000Z')
      end

      it 'returns nil for wrong type' do
        properties = { 'Updated' => { 'type' => 'text', 'text' => '2024-01-20' } }
        result = described_class.extract(properties, 'Updated', 'last_edited_time')
        expect(result).to be_nil
      end
    end

    describe 'status property' do
      it 'extracts status name' do
        properties = { 'Status' => { 'type' => 'status', 'status' => { 'name' => 'In Progress' } } }
        result = described_class.extract(properties, 'Status', 'status')
        expect(result).to eq('In Progress')
      end

      it 'returns nil for null status' do
        properties = { 'Status' => { 'type' => 'status', 'status' => nil } }
        result = described_class.extract(properties, 'Status', 'status')
        expect(result).to be_nil
      end

      it 'returns nil for wrong type' do
        properties = { 'Status' => { 'type' => 'text', 'text' => 'Done' } }
        result = described_class.extract(properties, 'Status', 'status')
        expect(result).to be_nil
      end
    end

    describe 'unknown property type' do
      it 'returns nil for unknown type' do
        properties = { 'Unknown' => { 'type' => 'unknown', 'unknown' => 'value' } }
        result = described_class.extract(properties, 'Unknown', 'unknown_type')
        expect(result).to be_nil
      end
    end

    describe 'rollup property' do
      it 'extracts first value from rollup array with title' do
        properties = {
          'Category' => {
            'type' => 'rollup',
            'rollup' => {
              'type' => 'array',
              'array' => [{ 'type' => 'title', 'title' => [{ 'plain_text' => 'Backend' }] }]
            }
          }
        }
        result = described_class.extract(properties, 'Category', 'rollup')
        expect(result).to eq('Backend')
      end

      it 'extracts first value from rollup array with rich_text' do
        properties = {
          'Category' => {
            'type' => 'rollup',
            'rollup' => {
              'type' => 'array',
              'array' => [{ 'type' => 'rich_text', 'rich_text' => [{ 'plain_text' => 'Description' }] }]
            }
          }
        }
        result = described_class.extract(properties, 'Category', 'rollup')
        expect(result).to eq('Description')
      end

      it 'extracts first value from rollup array with select' do
        properties = {
          'Category' => {
            'type' => 'rollup',
            'rollup' => {
              'type' => 'array',
              'array' => [{ 'type' => 'select', 'select' => { 'name' => 'Option A' } }]
            }
          }
        }
        result = described_class.extract(properties, 'Category', 'rollup')
        expect(result).to eq('Option A')
      end

      it 'extracts first value from rollup array with number' do
        properties = {
          'Category' => {
            'type' => 'rollup',
            'rollup' => {
              'type' => 'array',
              'array' => [{ 'type' => 'number', 'number' => 42 }]
            }
          }
        }
        result = described_class.extract(properties, 'Category', 'rollup')
        expect(result).to eq(42)
      end

      it 'returns nil for unknown item type in rollup array' do
        properties = {
          'Category' => {
            'type' => 'rollup',
            'rollup' => {
              'type' => 'array',
              'array' => [{ 'type' => 'unknown', 'unknown' => 'value' }]
            }
          }
        }
        result = described_class.extract(properties, 'Category', 'rollup')
        expect(result).to be_nil
      end

      it 'extracts number from rollup' do
        properties = {
          'Count' => {
            'type' => 'rollup',
            'rollup' => { 'type' => 'number', 'number' => 10 }
          }
        }
        result = described_class.extract(properties, 'Count', 'rollup')
        expect(result).to eq(10)
      end

      it 'extracts date from rollup' do
        properties = {
          'Due' => {
            'type' => 'rollup',
            'rollup' => { 'type' => 'date', 'date' => { 'start' => '2024-06-15' } }
          }
        }
        result = described_class.extract(properties, 'Due', 'rollup')
        expect(result).to eq('2024-06-15')
      end

      it 'returns nil for null date in rollup' do
        properties = {
          'Due' => {
            'type' => 'rollup',
            'rollup' => { 'type' => 'date', 'date' => nil }
          }
        }
        result = described_class.extract(properties, 'Due', 'rollup')
        expect(result).to be_nil
      end

      it 'returns nil for unknown rollup type' do
        properties = {
          'Data' => {
            'type' => 'rollup',
            'rollup' => { 'type' => 'unknown', 'unknown' => 'value' }
          }
        }
        result = described_class.extract(properties, 'Data', 'rollup')
        expect(result).to be_nil
      end

      it 'returns nil for wrong property type' do
        properties = { 'Data' => { 'type' => 'text', 'text' => 'value' } }
        result = described_class.extract(properties, 'Data', 'rollup')
        expect(result).to be_nil
      end

      it 'returns nil for null rollup' do
        properties = { 'Data' => { 'type' => 'rollup', 'rollup' => nil } }
        result = described_class.extract(properties, 'Data', 'rollup')
        expect(result).to be_nil
      end

      it 'returns nil for nil rollup array' do
        properties = {
          'Data' => {
            'type' => 'rollup',
            'rollup' => { 'type' => 'array', 'array' => nil }
          }
        }
        result = described_class.extract(properties, 'Data', 'rollup')
        expect(result).to be_nil
      end

      it 'returns nil for empty rollup array' do
        properties = {
          'Data' => {
            'type' => 'rollup',
            'rollup' => { 'type' => 'array', 'array' => [] }
          }
        }
        result = described_class.extract(properties, 'Data', 'rollup')
        expect(result).to be_nil
      end

      it 'returns nil for null select in rollup array' do
        properties = {
          'Category' => {
            'type' => 'rollup',
            'rollup' => {
              'type' => 'array',
              'array' => [{ 'type' => 'select', 'select' => nil }]
            }
          }
        }
        result = described_class.extract(properties, 'Category', 'rollup')
        expect(result).to be_nil
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

    it 'falls back to name when title is not present' do
      properties = {
        'Name' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Item Name' }] },
        'Level' => { 'type' => 'number', 'number' => 85 }
      }
      config = [
        { 'name' => 'Name', 'type' => 'title', 'key' => 'name' },
        { 'name' => 'Level', 'type' => 'number' }
      ]
      result = described_class.extract_all(properties, config)
      expect(result['title']).to eq('Item Name')
      expect(result['name']).to eq('Item Name')
    end

    it 'does not overwrite existing title with name' do
      properties = {
        'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Actual Title' }] },
        'Name' => { 'type' => 'rich_text', 'rich_text' => [{ 'plain_text' => 'Different Name' }] }
      }
      config = [
        { 'name' => 'Title', 'type' => 'title' },
        { 'name' => 'Name', 'type' => 'rich_text', 'key' => 'name' }
      ]
      result = described_class.extract_all(properties, config)
      expect(result['title']).to eq('Actual Title')
      expect(result['name']).to eq('Different Name')
    end

    it 'handles missing properties gracefully' do
      properties = {
        'Title' => { 'type' => 'title', 'title' => [{ 'plain_text' => 'Test' }] }
      }
      config = [
        { 'name' => 'Title', 'type' => 'title' },
        { 'name' => 'Missing', 'type' => 'number' }
      ]
      result = described_class.extract_all(properties, config)
      expect(result['title']).to eq('Test')
      expect(result['missing']).to be_nil
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
