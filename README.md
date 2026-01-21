# Jekyll Notion CMS

[![Gem Version](https://badge.fury.io/rb/jekyll-notion-cms.svg)](https://badge.fury.io/rb/jekyll-notion-cms)
[![CI](https://github.com/maxime-lenne/jekyll-notion-cms/actions/workflows/ci.yml/badge.svg)](https://github.com/maxime-lenne/jekyll-notion-cms/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A configurable Jekyll plugin that fetches content from Notion databases and makes it available as Jekyll data files.

## Features

- **Configurable Collections**: Define any number of Notion database collections via `_config.yml`
- **Multiple Organizers**: Support for different data organization patterns (simple list, grouped, skills by category, nested)
- **All Property Types**: Support for all Notion property types (text, number, date, select, multi-select, relations, rollups, formulas, files, etc.)
- **Fallback System**: Automatic fallback to Jekyll collections when Notion is unavailable
- **Pagination**: Handles large databases with automatic pagination
- **Caching**: Intelligent file caching to avoid unnecessary regenerations

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jekyll-notion-cms'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install jekyll-notion-cms
```

## Quick Start

### 1. Set up your Notion Integration

1. Go to [Notion Developers](https://www.notion.so/my-integrations)
2. Create a new integration
3. Copy the Internal Integration Token
4. Share your Notion databases with the integration

### 2. Configure Environment Variables

```bash
export NOTION_TOKEN=secret_xxx
export NOTION_EXPERIENCES_DB=your_database_id
export NOTION_BLOG_DB=your_blog_database_id
```

### 3. Add Configuration to `_config.yml`

```yaml
notion:
  enabled: true

  collections:
    experiences:
      database_env: NOTION_EXPERIENCES_DB
      data_file: notion_experiences.yml
      organizer: simple_list
      sort_by: order
      properties:
        - { name: Title, type: title }
        - { name: Company, type: rich_text }
        - { name: Start Date, type: date, key: start_date }
        - { name: Current, type: checkbox }
        - { name: Tags, type: multi_select }

    blog_posts:
      database_env: NOTION_BLOG_DB
      data_file: notion_blog_posts.yml
      organizer: simple_list
      sort_by: published_at
      sort_order: desc
      properties:
        - { name: Title, type: title }
        - { name: Slug, type: rich_text }
        - { name: Language, type: select }
        - { name: Published At, type: date, key: published_at }
        - { name: Status, type: select }
        - { name: Excerpt, type: rich_text }
        - { name: Tags, type: multi_select }
```

### 4. Use Data in Templates

```liquid
{% for exp in site.data.notion_experiences %}
  <h3>{{ exp.title }}</h3>
  <p>{{ exp.company }} - {{ exp.start_date }}</p>
{% endfor %}
```

## Configuration Reference

### Collection Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `database_env` | String | Yes | Environment variable containing the Notion database ID |
| `data_file` | String | Yes | Output filename in `_data/` directory |
| `organizer` | String | No | Data organization method (default: `simple_list`) |
| `sort_by` | String | No | Property key to sort by |
| `sort_order` | String | No | `asc` (default) or `desc` |
| `group_by` | String | No | Field to group by (for `grouped_by` organizer) |
| `properties` | Array | Yes | Property mapping configuration |

### Organizer Types

#### `simple_list` (default)

Returns an array of items sorted by the specified field.

```yaml
organizer: simple_list
sort_by: order
sort_order: asc
```

#### `skills_by_category`

Groups skills by their category. Designed for skills/competencies display.

```yaml
organizer: skills_by_category
```

Output structure:
```yaml
Backend:
  title: Backend
  icon: code
  order: 1
  skills:
    - name: Ruby
      level: 90
      years: 10
```

#### `grouped_by`

Groups items by a specified field.

```yaml
organizer: grouped_by
group_by: category
sort_by: order
```

#### `nested`

Creates a hierarchical tree structure based on parent-child relationships.

```yaml
organizer: nested
parent_field: parent_id
sort_by: order
```

### Property Types

| Type | Notion Property | Output |
|------|-----------------|--------|
| `title` | Title | String |
| `rich_text` | Rich text, Text | String |
| `number` | Number | Integer/Float |
| `checkbox` | Checkbox | Boolean |
| `date` | Date | Hash with `start`, `end`, `time_zone` |
| `select` | Select | String |
| `multi_select` | Multi-select | Array of strings |
| `url` | URL | String |
| `email` | Email | String |
| `phone_number` | Phone | String |
| `files` | Files & media | Array of file objects |
| `rollup` | Rollup | Value from related database |
| `formula` | Formula | Computed value |
| `formula_array` | Formula (array) | Array of values |
| `relation` | Relation | Array of page IDs |
| `people` | Person | Array of user objects |
| `status` | Status | String |
| `created_time` | Created time | ISO timestamp |
| `last_edited_time` | Last edited | ISO timestamp |

### Property Configuration

```yaml
properties:
  - name: "Property Name"    # Name in Notion (required)
    type: rich_text          # Property type (required)
    key: custom_key          # Output key (optional, defaults to snake_case)
```

## Fallback System

When Notion is unavailable, the plugin automatically falls back to Jekyll collections:

1. **No `NOTION_TOKEN`**: Uses all Jekyll collections
2. **Missing database ID**: Uses fallback for that collection
3. **API Error**: Falls back gracefully with error logging

Create fallback collections in `_collections/`:

```
_collections/
├── _experiences/
│   ├── experience-1.md
│   └── experience-2.md
└── _blog_posts/
    └── my-post.md
```

## GitHub Actions

```yaml
- name: Build with Jekyll
  env:
    NOTION_TOKEN: ${{ secrets.NOTION_TOKEN }}
    NOTION_EXPERIENCES_DB: ${{ secrets.NOTION_EXPERIENCES_DB }}
    NOTION_BLOG_DB: ${{ secrets.NOTION_BLOG_DB }}
  run: bundle exec jekyll build
```

## Development

After checking out the repo:

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Run console
bundle exec rake console
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/maxime-lenne/jekyll-notion-cms.

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

**Maxime Lenne** - [maxime-lenne.fr](https://maxime-lenne.fr)

- GitHub: [@maxime-lenne](https://github.com/maxime-lenne)
- LinkedIn: [maximelenne](https://linkedin.com/in/maximelenne)
