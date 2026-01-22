# Jekyll Notion CMS

<p align="center">
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/notion/notion-original.svg" alt="Notion" width="80" height="80" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/jekyll/jekyll-original.svg" alt="Jekyll" width="80" height="80" />
  <img src="https://upload.vectorlogo.zone/logos/n8nio/images/b751b1e9-f500-4b33-b8b1-3b8126059c0c.svg" alt="n8n" width="80" height="80" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/githubactions/githubactions-original-wordmark.svg" alt="Github Action" width="80" height="80" />
</p>

<p align="center">
  <strong>Use Notion as a CMS for your Jekyll static site</strong>
</p>

<p align="center">
  <a href="https://badge.fury.io/rb/jekyll-notion-cms"><img src="https://badge.fury.io/rb/jekyll-notion-cms.svg" alt="Gem Version" /></a>
  <a href="https://github.com/maxime-lenne/jekyll-notion-cms/actions/workflows/ci.yml"><img src="https://github.com/maxime-lenne/jekyll-notion-cms/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
</p>

---

A configurable Jekyll plugin that fetches content from Notion databases and makes it available as Jekyll data files. Perfect for building landing pages, portfolios, blogs, and resumes with Notion as your content management system.

## Features

- **Configurable Collections**: Define any number of Notion database collections via `_config.yml`
- **Multiple Organizers**: Support for different data organization patterns (simple list, grouped, skills by category, nested)
- **All Property Types**: Support for all Notion property types (text, number, date, select, multi-select, relations, rollups, formulas, files, etc.)
- **Fallback System**: Automatic fallback to Jekyll collections when Notion is unavailable
- **Pagination**: Handles large databases with automatic pagination
- **Caching**: Intelligent file caching to avoid unnecessary regenerations


## Architecture

<p align="center">
  <img src="docs/architecture.png" alt="Jekyll Notion CMS Architecture" width="800" />
</p>

The diagram above shows how Jekyll Notion CMS integrates with your workflow:

1. **Content editing** in Notion databases
2. **Change detection** via n8n polling or webhooks
3. **Build trigger** through GitHub Actions workflow_dispatch
4. **Static site generation** with Jekyll + jekyll-notion-cms
5. **Deployment** to GitHub Pages (or any static host)

## Use Cases

### Landing Page

Build dynamic landing pages with content managed entirely in Notion:

| Content Type | Notion Database | Description |
|--------------|-----------------|-------------|
| **Services** | Services DB | List your offerings with icons, descriptions, and pricing |
| **Testimonials** | Testimonials DB | Client reviews with photos, quotes, and ratings |
| **Team** | Team DB | Team member profiles with photos and bios |
| **FAQ** | FAQ DB | Frequently asked questions organized by category |

### Portfolio

Showcase your work with a portfolio powered by Notion:

| Content Type | Notion Database | Description |
|--------------|-----------------|-------------|
| **Projects** | Projects DB | Portfolio pieces with images, descriptions, and links |
| **Skills** | Skills DB | Technical skills organized by category with proficiency levels |
| **Certifications** | Certifications DB | Professional certifications and badges |

### Blog

Run a full-featured blog with Notion as your writing tool:

| Content Type | Notion Database | Description |
|--------------|-----------------|-------------|
| **Posts** | Blog DB | Articles with rich text, tags, and publication dates |
| **Categories** | Categories DB | Blog categories for organization |
| **Authors** | Authors DB | Author profiles for multi-author blogs |

### Resume / CV

Create a dynamic online resume:

| Content Type | Notion Database | Description |
|--------------|-----------------|-------------|
| **Experiences** | Experiences DB | Work history with dates, companies, and descriptions |
| **Education** | Education DB | Academic background and degrees |
| **Skills** | Skills DB | Technical and soft skills with proficiency |
| **Languages** | Languages DB | Language proficiencies |

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

## Examples

### Projects Database

Perfect for portfolios and case studies.

**Notion Database Structure:**

| Property | Type | Description |
|----------|------|-------------|
| Name | Title | Project name |
| Description | Rich text | Project description |
| Image | Files | Cover image |
| Tags | Multi-select | Technologies used |
| URL | URL | Live project link |
| GitHub | URL | Repository link |
| Featured | Checkbox | Show on homepage |
| Order | Number | Display order |

**Configuration:**

```yaml
notion:
  collections:
    projects:
      database_env: NOTION_PROJECTS_DB
      data_file: notion_projects.yml
      organizer: simple_list
      sort_by: order
      properties:
        - { name: Name, type: title }
        - { name: Description, type: rich_text }
        - { name: Image, type: files }
        - { name: Tags, type: multi_select }
        - { name: URL, type: url }
        - { name: GitHub, type: url, key: github_url }
        - { name: Featured, type: checkbox }
        - { name: Order, type: number }
```

**Template Usage:**

```liquid
{% for project in site.data.notion_projects %}
  {% if project.featured %}
  <article class="project-card">
    {% if project.image.first %}
      <img src="{{ project.image.first.url }}" alt="{{ project.title }}" />
    {% endif %}
    <h3>{{ project.title }}</h3>
    <p>{{ project.description }}</p>
    <div class="tags">
      {% for tag in project.tags %}
        <span class="tag">{{ tag }}</span>
      {% endfor %}
    </div>
    <div class="links">
      {% if project.url %}<a href="{{ project.url }}">View Project</a>{% endif %}
      {% if project.github_url %}<a href="{{ project.github_url }}">GitHub</a>{% endif %}
    </div>
  </article>
  {% endif %}
{% endfor %}
```

---

### Services Database

Ideal for freelancers and agencies.

**Notion Database Structure:**

| Property | Type | Description |
|----------|------|-------------|
| Name | Title | Service name |
| Description | Rich text | Service description |
| Icon | Select | Icon identifier (e.g., "code", "design") |
| Price | Rich text | Pricing information |
| Features | Rich text | Key features (bullet points) |
| Category | Select | Service category |
| Order | Number | Display order |

**Configuration:**

```yaml
notion:
  collections:
    services:
      database_env: NOTION_SERVICES_DB
      data_file: notion_services.yml
      organizer: grouped_by
      group_by: category
      sort_by: order
      properties:
        - { name: Name, type: title }
        - { name: Description, type: rich_text }
        - { name: Icon, type: select }
        - { name: Price, type: rich_text }
        - { name: Features, type: rich_text }
        - { name: Category, type: select }
        - { name: Order, type: number }
```

**Template Usage:**

```liquid
{% for category in site.data.notion_services %}
  <section class="service-category">
    <h2>{{ category[0] }}</h2>
    {% for service in category[1] %}
      <div class="service-card">
        <i class="icon-{{ service.icon }}"></i>
        <h3>{{ service.title }}</h3>
        <p>{{ service.description }}</p>
        <p class="price">{{ service.price }}</p>
      </div>
    {% endfor %}
  </section>
{% endfor %}
```

---

### Testimonials Database

Build trust with client testimonials.

**Notion Database Structure:**

| Property | Type | Description |
|----------|------|-------------|
| Quote | Title | Testimonial text |
| Author | Rich text | Client name |
| Role | Rich text | Client's job title |
| Company | Rich text | Client's company |
| Avatar | Files | Client photo |
| Rating | Number | Star rating (1-5) |
| Featured | Checkbox | Show on homepage |
| Date | Date | Testimonial date |

**Configuration:**

```yaml
notion:
  collections:
    testimonials:
      database_env: NOTION_TESTIMONIALS_DB
      data_file: notion_testimonials.yml
      organizer: simple_list
      sort_by: date
      sort_order: desc
      properties:
        - { name: Quote, type: title }
        - { name: Author, type: rich_text }
        - { name: Role, type: rich_text }
        - { name: Company, type: rich_text }
        - { name: Avatar, type: files }
        - { name: Rating, type: number }
        - { name: Featured, type: checkbox }
        - { name: Date, type: date }
```

**Template Usage:**

```liquid
<section class="testimonials">
  {% for testimonial in site.data.notion_testimonials %}
    {% if testimonial.featured %}
    <blockquote class="testimonial">
      <div class="stars">
        {% for i in (1..testimonial.rating) %}
          <span class="star">★</span>
        {% endfor %}
      </div>
      <p>"{{ testimonial.title }}"</p>
      <footer>
        {% if testimonial.avatar.first %}
          <img src="{{ testimonial.avatar.first.url }}" alt="{{ testimonial.author }}" class="avatar" />
        {% endif %}
        <cite>
          <strong>{{ testimonial.author }}</strong>
          <span>{{ testimonial.role }}, {{ testimonial.company }}</span>
        </cite>
      </footer>
    </blockquote>
    {% endif %}
  {% endfor %}
</section>
```

---

### Skills Database

Showcase your technical expertise.

**Notion Database Structure:**

| Property | Type | Description |
|----------|------|-------------|
| Name | Title | Skill name |
| Category | Select | Skill category (Backend, Frontend, etc.) |
| Level | Select/Number | Proficiency level |
| Icon | Rich text | Icon class or URL |
| Years | Number | Years of experience |
| Order | Number | Display order within category |

**Configuration:**

```yaml
notion:
  collections:
    skills:
      database_env: NOTION_SKILLS_DB
      data_file: notion_skills.yml
      organizer: items_by_category
      properties:
        - { name: Name, type: title }
        - { name: Category, type: rollup }
        - { name: Level, type: number }
        - { name: Icon, type: rich_text }
        - { name: Years, type: number }
        - { name: Order, type: number }
        - { name: Category Icon, type: rollup, key: category_icon }
        - { name: Category Order, type: rollup, key: category_order }
```

**Template Usage:**

```liquid
{% for category in site.data.notion_skills %}
  <section class="skill-category">
    <h3>
      <i class="{{ category[1].icon }}"></i>
      {{ category[1].title }}
    </h3>
    <div class="skills-grid">
      {% for item in category[1].items %}
        <div class="skill">
          <span class="skill-name">{{ item.name }}</span>
          <div class="skill-bar">
            <div class="skill-level" style="width: {{ item.level }}%"></div>
          </div>
          <span class="skill-years">{{ item.years }} years</span>
        </div>
      {% endfor %}
    </div>
  </section>
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

#### `items_by_category`

Groups items by their category. Useful for skills, products, team members, or any categorized content.

```yaml
organizer: items_by_category
```

Output structure:
```yaml
Backend:
  title: Backend
  icon: code
  order: 1
  items:
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

## Automation & Deployment

### GitHub Actions Workflow

Copy the workflow template to your repository:

```bash
cp docs/templates/github-actions_notion-sync.yml .github/workflows/notion-sync.yml
```

**Full workflow file:** [`docs/templates/github-actions_notion-sync.yml`](docs/templates/github-actions_notion-sync.yml)

```yaml
name: Notion Sync Workflow

on:
  workflow_dispatch:
    inputs:
      notion_event:
        description: 'Type of Notion event'
        required: true
        type: string
      page_id:
        description: 'Notion page ID'
        required: true
        type: string
      database_id:
        description: 'Notion database ID'
        required: true
        type: string
      updated_at:
        description: 'Last update timestamp'
        required: true
        type: string

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Build with Jekyll
        run: bundle exec jekyll build
        env:
          JEKYLL_ENV: production
          NOTION_TOKEN: ${{ secrets.NOTION_TOKEN }}
          NOTION_SKILLS_DB: ${{ secrets.NOTION_SKILLS_DB }}
          NOTION_EXPERIENCES_DB: ${{ secrets.NOTION_EXPERIENCES_DB }}
          NOTION_BLOG_DB: ${{ secrets.NOTION_BLOG_DB }}
          # Add more database secrets as needed

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Automatic Sync with n8n


Use [n8n](https://n8n.io) to automatically trigger builds when Notion content changes.

**Import the workflow template:** [`docs/templates/n8n-workflow_Notion-database-change-trigger-GitHub-Actions.json`](docs/templates/n8n-workflow_Notion-database-change-trigger-GitHub-Actions.json)

**Workflow steps:**

1. **Notion Trigger** - Polls Notion database for changes (configurable interval)
2. **GitHub Action** - Triggers `workflow_dispatch` event on your repository
3. **Notification** (optional) - Sends Telegram/Slack message on deployment

**n8n Configuration:**

| Node | Configuration |
|------|---------------|
| Notion Trigger | Database ID, poll interval (e.g., every hour) |
| GitHub | Repository owner, repo name, workflow ID, branch |
| Telegram/Slack | Chat ID for notifications (optional) |

**Required credentials:**
- Notion API integration token
- GitHub Personal Access Token (with `repo` and `workflow` scopes)

### Manual Trigger

You can also trigger the workflow manually via GitHub CLI:

```bash
gh workflow run notion-sync.yml \
  -f notion_event=manual \
  -f page_id=none \
  -f database_id=all \
  -f updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

Or via the GitHub Actions UI by clicking "Run workflow" on the Actions tab.

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
