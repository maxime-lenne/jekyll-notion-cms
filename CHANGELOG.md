# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-01-26

### Fixed

- Category order now correctly handles array values from rollup properties
  - Fixes sorting of categories when `Category Order` returns an array instead of a single value

## [1.0.1] - 2026-01-22

### Fixed

- Rollup arrays now return all values instead of only the first one
  - Single value: returns the value directly
  - Multiple values: returns an array of values

## [1.0.0] - 2026-01-21

### Added

- Initial release of jekyll-notion-cms
- Configurable collections via `_config.yml`
- Support for multiple Notion property types:
  - Title, Rich text, Number, Checkbox
  - Date, Select, Multi-select, URL
  - Email, Phone number, Files
  - Rollup, Formula, Relation
  - People, Status, Created/Last edited time
- Multiple data organizers:
  - `simple_list` - Sorted array of items
  - `items_by_category` - Items grouped by category (skills, products, etc.)
  - `grouped_by` - Items grouped by a field
  - `nested` - Hierarchical tree structure
- Automatic fallback to Jekyll collections
- Pagination support for large databases
- Data file caching to avoid unnecessary regeneration
- Comprehensive logging
- Documentation: use cases, examples (projects, services, testimonials, skills)
- Documentation: automation section with GitHub Actions and n8n workflow templates
- Architecture diagram

### Security

- Secure handling of Notion API tokens via environment variables

[1.0.2]: https://github.com/maxime-lenne/jekyll-notion-cms/releases/tag/v1.0.2
[1.0.1]: https://github.com/maxime-lenne/jekyll-notion-cms/releases/tag/v1.0.1
[1.0.0]: https://github.com/maxime-lenne/jekyll-notion-cms/releases/tag/v1.0.0
