# Tasks

## To do

### Rollup with a single value returns a scalar instead of an array

`PropertyExtractors.extract_rollup_array` returns the value alone when a rollup has one item, and an
array otherwise (since 1.0.1). A property meant to be a list, such as the `Skills` of an experience,
is then a string for items with a single skill.

Templates that iterate with Liquid do not notice, but anything that expects an array breaks: for
example `{{ experience.skills | jsonify }}` followed by `.map()` in JavaScript fails with
`skills.slice(...).map is not a function`.

**Proposal (1.1.0):** add an opt-in option on the property, so existing sites keep their behavior:

```yaml
properties:
  - { name: Skills, type: rollup, array: true }
```

With `array: true`, the extractor always returns an array: `[]` when empty, `[value]` for a single
value. Document it in the README and `docs/EXAMPLES_AND_CONFIGURATION.md`, and cover the three cases
(empty, one value, several values) in `property_extractors_spec.rb`.

A default change (always an array) would be a breaking change and belongs to 2.0.
