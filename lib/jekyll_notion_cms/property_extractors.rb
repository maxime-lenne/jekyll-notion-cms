# frozen_string_literal: true

module JekyllNotionCMS
  # Module for extracting values from Notion property types
  module PropertyExtractors
    module_function

    # Extract a property value based on its type
    # @param properties [Hash] The properties hash from a Notion page
    # @param property_name [String] The name of the property
    # @param property_type [String] The expected type of the property
    # @return [Object] The extracted value
    def extract(properties, property_name, property_type)
      property = properties[property_name]
      return nil unless property

      case property_type
      when 'title'
        extract_title(property)
      when 'rich_text'
        extract_rich_text(property)
      when 'number'
        extract_number(property)
      when 'checkbox'
        extract_checkbox(property)
      when 'date'
        extract_date(property)
      when 'select'
        extract_select(property)
      when 'multi_select'
        extract_multi_select(property)
      when 'url'
        extract_url(property)
      when 'email'
        extract_email(property)
      when 'phone_number'
        extract_phone_number(property)
      when 'rollup'
        extract_rollup(property)
      when 'formula'
        extract_formula(property)
      when 'formula_array'
        extract_formula_array(property)
      when 'relation'
        extract_relation(property)
      when 'people'
        extract_people(property)
      when 'files'
        extract_files(property)
      when 'created_time'
        extract_created_time(property)
      when 'last_edited_time'
        extract_last_edited_time(property)
      when 'status'
        extract_status(property)
      else
        nil
      end
    end

    # Extract all properties from a Notion page based on configuration
    # @param properties [Hash] The properties hash from a Notion page
    # @param properties_config [Array<Hash>] Configuration for each property
    # @return [Hash] Extracted properties with normalized keys
    def extract_all(properties, properties_config)
      item = {}

      properties_config.each do |prop_config|
        prop_name = prop_config['name']
        prop_type = prop_config['type']
        prop_key = prop_config['key'] || normalize_key(prop_name)

        value = extract(properties, prop_name, prop_type)
        item[prop_key] = value
      end

      # Use 'title' as the main identifier, fall back to 'name'
      item['title'] ||= item['name']

      item
    end

    # Normalize a property name to a valid key
    # @param name [String] The property name
    # @return [String] The normalized key
    def normalize_key(name)
      name.downcase.gsub(/\s+/, '_')
    end

    # Title property
    def extract_title(property)
      return nil unless property['type'] == 'title'

      property['title'].map { |text| text['plain_text'] }.join('')
    end

    # Rich text property
    def extract_rich_text(property)
      return nil unless property['type'] == 'rich_text'
      return nil if property['rich_text'].nil? || property['rich_text'].empty?

      property['rich_text'].map { |text| text['plain_text'] }.join('')
    end

    # Number property (also handles select-to-number conversion)
    def extract_number(property)
      case property['type']
      when 'number'
        property['number']
      when 'select'
        convert_select_to_number(property['select']&.dig('name'))
      else
        nil
      end
    end

    # Convert common select values to numbers
    def convert_select_to_number(value)
      case value
      when 'Expert', 'Avancé', 'Advanced' then 90
      when 'Intermédiaire', 'Intermediate' then 70
      when 'Débutant', 'Beginner' then 50
      else nil
      end
    end

    # Checkbox property
    def extract_checkbox(property)
      property['type'] == 'checkbox' ? property['checkbox'] : false
    end

    # Date property
    def extract_date(property)
      return nil unless property['type'] == 'date'
      return nil if property['date'].nil?

      {
        'start' => property['date']['start'],
        'end' => property['date']['end'],
        'time_zone' => property['date']['time_zone']
      }.compact
    end

    # Select property
    def extract_select(property)
      return nil unless property['type'] == 'select'

      property['select']&.dig('name')
    end

    # Multi-select property
    def extract_multi_select(property)
      return [] unless property['type'] == 'multi_select'

      property['multi_select'].map { |item| item['name'] }
    end

    # URL property (also handles rich_text containing URLs)
    def extract_url(property)
      case property['type']
      when 'url'
        property['url']
      when 'rich_text'
        extract_rich_text(property)
      else
        nil
      end
    end

    # Email property
    def extract_email(property)
      return nil unless property['type'] == 'email'

      property['email']
    end

    # Phone number property
    def extract_phone_number(property)
      return nil unless property['type'] == 'phone_number'

      property['phone_number']
    end

    # Rollup property
    def extract_rollup(property)
      return nil unless property['type'] == 'rollup'
      return nil unless property['rollup']

      rollup = property['rollup']

      case rollup['type']
      when 'array'
        extract_rollup_array(rollup['array'])
      when 'number'
        rollup['number']
      when 'date'
        rollup['date']&.dig('start')
      else
        nil
      end
    end

    # Extract first value from rollup array
    def extract_rollup_array(array)
      return nil if array.nil? || array.empty?

      array.map do |item|
        case item['type']
        when 'title'
          item['title'].map { |text| text['plain_text'] }.join('')
        when 'rich_text'
          item['rich_text'].map { |text| text['plain_text'] }.join('')
        when 'select'
          item['select']&.dig('name')
        when 'number'
          item['number']
        else
          nil
        end
      end.compact.first
    end

    # Formula property
    def extract_formula(property)
      return nil unless property['type'] == 'formula'
      return nil if property['formula'].nil?

      formula = property['formula']

      case formula['type']
      when 'string'
        formula['string']
      when 'number'
        formula['number']
      when 'boolean'
        formula['boolean']
      when 'date'
        formula['date']&.dig('start')
      else
        nil
      end
    end

    # Formula returning array
    def extract_formula_array(property)
      return [] unless property['type'] == 'formula'
      return [] if property['formula'].nil?

      formula = property['formula']

      case formula['type']
      when 'array'
        extract_formula_array_items(formula['array'])
      when 'string'
        parse_formula_string(formula['string'])
      else
        []
      end
    end

    # Extract items from formula array
    def extract_formula_array_items(array)
      return [] unless array

      array.map do |item|
        case item['type']
        when 'string'
          item['string']
        when 'rich_text'
          item['rich_text']&.map { |text| text['plain_text'] }&.join('')
        else
          nil
        end
      end.compact
    end

    # Parse formula string to array (split by delimiter)
    def parse_formula_string(string_value)
      return [] if string_value.nil? || string_value.empty?

      string_value.split(/- /).map do |item|
        cleaned = item.strip.gsub(/^\.+|\.+$/, '')
        cleaned.empty? ? nil : cleaned
      end.compact
    end

    # Relation property
    def extract_relation(property)
      return [] unless property['type'] == 'relation'
      return [] if property['relation'].nil? || property['relation'].empty?

      property['relation'].map { |relation| relation['id'] }
    end

    # People property
    def extract_people(property)
      return [] unless property['type'] == 'people'
      return [] if property['people'].nil? || property['people'].empty?

      property['people'].map do |person|
        {
          'id' => person['id'],
          'name' => person['name'],
          'email' => person.dig('person', 'email'),
          'avatar_url' => person['avatar_url']
        }.compact
      end
    end

    # Files property
    def extract_files(property)
      return [] unless property['type'] == 'files'
      return [] if property['files'].nil? || property['files'].empty?

      property['files'].map do |file|
        url = file.dig('file', 'url') || file.dig('external', 'url')
        {
          'name' => file['name'],
          'url' => url,
          'type' => file['type']
        }.compact
      end
    end

    # Created time property
    def extract_created_time(property)
      return nil unless property['type'] == 'created_time'

      property['created_time']
    end

    # Last edited time property
    def extract_last_edited_time(property)
      return nil unless property['type'] == 'last_edited_time'

      property['last_edited_time']
    end

    # Status property
    def extract_status(property)
      return nil unless property['type'] == 'status'

      property['status']&.dig('name')
    end
  end
end
