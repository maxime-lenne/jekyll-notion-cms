# Examples & Configuration Reference

This document provides detailed examples and configuration reference for jekyll-notion-cms.

## Table of Contents

- [Examples](#examples)
  - [Projects Database](#projects-database)
  - [Services Database](#services-database)
  - [Testimonials Database](#testimonials-database)
  - [Skills Database](#skills-database)
- [Configuration Reference](#configuration-reference)
  - [Collection Options](#collection-options)
  - [Organizer Types](#organizer-types)
  - [Property Types](#property-types)
  - [Property Configuration](#property-configuration)

---

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

---

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
| `rollup` | Rollup | Single value or array from related database |
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
