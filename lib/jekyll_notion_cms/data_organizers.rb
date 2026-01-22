# frozen_string_literal: true

module JekyllNotionCMS
  # Module for organizing Notion data into different structures
  module DataOrganizers
    module_function

    # Organize data based on the specified organizer type
    # @param notion_data [Hash] Raw data from Notion API
    # @param config [Hash] Collection configuration
    # @return [Hash, Array] Organized data
    def organize(notion_data, config)
      organizer = config['organizer'] || 'simple_list'
      properties_config = config['properties'] || []
      sort_by = config['sort_by']
      sort_order = config['sort_order'] || 'asc'

      case organizer
      when 'simple_list'
        organize_simple_list(notion_data, properties_config, sort_by, sort_order)
      when 'items_by_category'
        organize_items_by_category(notion_data, properties_config)
      when 'grouped_by'
        group_field = config['group_by']
        organize_grouped_by(notion_data, properties_config, group_field, sort_by, sort_order)
      when 'nested'
        parent_field = config['parent_field'] || 'parent_id'
        organize_nested(notion_data, properties_config, parent_field, sort_by, sort_order)
      else
        organize_simple_list(notion_data, properties_config, sort_by, sort_order)
      end
    end

    # Organize as a simple sorted list
    # @param notion_data [Hash] Raw data from Notion API
    # @param properties_config [Array<Hash>] Property configuration
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order ('asc' or 'desc')
    # @return [Array<Hash>] Sorted list of items
    def organize_simple_list(notion_data, properties_config, sort_by, sort_order)
      items = notion_data['results'].map do |page|
        item = PropertyExtractors.extract_all(page['properties'], properties_config)
        item['id'] = page['id']
        item['created_time'] = page['created_time']
        item['last_edited_time'] = page['last_edited_time']
        item
      end

      # Filter out items without title
      items = items.select { |item| item['title'] && !item['title'].to_s.empty? }

      # Sort if sort_by is specified
      sort_items(items, sort_by, sort_order)
    end

    # Organize items grouped by category
    # Useful for skills, products, team members, or any items with category grouping
    # @param notion_data [Hash] Raw data from Notion API
    # @param properties_config [Array<Hash>] Property configuration
    # @return [Hash] Items grouped by category
    def organize_items_by_category(notion_data, _properties_config)
      items_by_category = {}

      notion_data['results'].each do |page|
        properties = page['properties']

        name = PropertyExtractors.extract(properties, 'Name', 'title')
        next if name.nil? || name.empty?

        level = PropertyExtractors.extract(properties, 'Level', 'number')
        years = PropertyExtractors.extract(properties, 'Years', 'number')
        featured = PropertyExtractors.extract(properties, 'Featured', 'checkbox')
        order = PropertyExtractors.extract(properties, 'Order', 'number')
        category_name = PropertyExtractors.extract(properties, 'Category', 'rollup') || 'Other'
        category_icon = PropertyExtractors.extract(properties, 'Icon', 'rollup')
        category_color = PropertyExtractors.extract(properties, 'Color', 'rollup')
        category_order = PropertyExtractors.extract(properties, 'Category Order', 'rollup')

        items_by_category[category_name] ||= {
          'title' => category_name,
          'category' => category_name,
          'subcategory' => nil,
          'icon' => category_icon,
          'order' => category_order || 999,
          'items' => []
        }

        items_by_category[category_name]['items'] << {
          'name' => name,
          'level' => level,
          'years' => years,
          'description' => nil,
          'icon' => nil,
          'color' => category_color,
          'featured' => featured,
          'order' => order || 999,
          'id' => page['id']
        }
      end

      # Sort categories by order
      items_by_category = items_by_category.sort_by { |_, data| data['order'].to_i }.to_h

      # Sort items within each category
      items_by_category.each_value do |data|
        data['items'].sort_by! { |item| item['order'].to_i }
      end

      items_by_category
    end

    # Organize items grouped by a field
    # @param notion_data [Hash] Raw data from Notion API
    # @param properties_config [Array<Hash>] Property configuration
    # @param group_field [String] Field to group by
    # @param sort_by [String] Field to sort by within groups
    # @param sort_order [String] Sort order
    # @return [Hash] Items grouped by field
    def organize_grouped_by(notion_data, properties_config, group_field, sort_by, sort_order)
      grouped = {}

      notion_data['results'].each do |page|
        item = PropertyExtractors.extract_all(page['properties'], properties_config)
        item['id'] = page['id']

        next if item['title'].nil? || item['title'].to_s.empty?

        group_key = item[group_field]
        group_key = group_key.first if group_key.is_a?(Array)
        group_key ||= 'Other'

        grouped[group_key] ||= []
        grouped[group_key] << item
      end

      # Sort within groups
      grouped.each_value do |items|
        sort_items(items, sort_by, sort_order)
      end

      grouped
    end

    # Organize items in a nested tree structure
    # @param notion_data [Hash] Raw data from Notion API
    # @param properties_config [Array<Hash>] Property configuration
    # @param parent_field [String] Field containing parent reference
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order
    # @return [Array<Hash>] Nested tree of items
    def organize_nested(notion_data, properties_config, parent_field, sort_by, sort_order)
      items = {}
      roots = []

      # First pass: extract all items
      notion_data['results'].each do |page|
        item = PropertyExtractors.extract_all(page['properties'], properties_config)
        item['id'] = page['id']
        item['children'] = []
        items[page['id']] = item
      end

      # Second pass: build tree structure
      items.each_value do |item|
        parent_ids = item[parent_field]
        parent_id = parent_ids.is_a?(Array) ? parent_ids.first : parent_ids

        if parent_id && items[parent_id]
          items[parent_id]['children'] << item
        else
          roots << item
        end
      end

      # Sort at each level
      sort_nested(roots, sort_by, sort_order)

      roots
    end

    # Sort items by field
    # @param items [Array<Hash>] Items to sort
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order ('asc' or 'desc')
    # @return [Array<Hash>] Sorted items
    def sort_items(items, sort_by, sort_order)
      return items unless sort_by && !sort_by.empty?

      items.sort_by! do |item|
        value = item[sort_by]
        case value
        when nil then sort_order == 'desc' ? -Float::INFINITY : Float::INFINITY
        when Numeric then value
        when String then value.downcase
        when Hash then value['start'] || '' # For date objects
        else value.to_s.downcase
        end
      end

      items.reverse! if sort_order == 'desc'
      items
    end

    # Recursively sort nested items
    # @param items [Array<Hash>] Items to sort
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order
    def sort_nested(items, sort_by, sort_order)
      sort_items(items, sort_by, sort_order)

      items.each do |item|
        sort_nested(item['children'], sort_by, sort_order) if item['children']&.any?
      end
    end

    # Check if data is present (non-empty)
    # @param data [Hash, Array] Data to check
    # @return [Boolean] True if data is present
    def data_present?(data)
      return false if data.nil?

      if data.is_a?(Hash)
        data.size.positive?
      else
        data.length.positive?
      end
    end
  end
end
