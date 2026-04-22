# Prompts: Tests and Documentation

These prompts work best with the `documentation-quality` skill active.
The skill teaches Claude what good descriptions look like, so you don't
have to repeat quality criteria in every prompt.

---

## Generate full schema for a model

```
Add a complete schema entry for [model_name] in [yaml_file].

Include:
- Model description (state the grain, what it contains, when to use it)
- Column descriptions for ALL columns
- Appropriate tests:
  - unique + not_null on primary key
  - not_null on important fields
  - accepted_values where applicable
  - relationships to upstream models
  - expression tests for business rules (e.g., amount >= 0)
```

### Example — concrete version:

```
Add a complete schema entry for the orders model in models/marts/_marts_models.yml.

Include:
- Model description (grain: one row per order, contents, when to use vs customers mart)
- Column descriptions for ALL columns
- Tests:
  - unique + not_null on order_id
  - not_null on customer_id, order_date, order_status
  - accepted_values on order_status: placed, shipped, completed, return_pending, returned
  - relationships: customer_id to stg_customers
  - expression: total_amount >= 0
```

---

## Add tests to an existing schema

```
Look at [model_path] and add missing tests to [yaml_file].

The model currently has [describe what exists].
Add tests for:
- [specific test 1]
- [specific test 2]

Do not change existing descriptions or tests. Only add new ones.
```

### Example — concrete version:

```
Look at models/marts/customers.sql and add missing tests to _marts_models.yml.

The model currently has unique + not_null on customer_id.
Add tests for:
- not_null on first_name, last_name, email
- lifetime_value >= 0 (expression test using dbt_utils)
- number_of_orders >= 0

Do not change existing descriptions or tests. Only add new ones.
```

---

## Improve existing descriptions

```
Review the column descriptions in [yaml_file] for [model_name].

Rewrite any descriptions that:
- Just restate the column name (e.g., "The customer ID")
- Don't explain what null or zero means
- Don't state the unit for numeric fields

Keep the tests unchanged. Only improve descriptions.
```

### Example — concrete version:

```
Review the column descriptions in _marts_models.yml for the customers model.

Rewrite any descriptions that:
- Just restate the column name (e.g., "The email of the customer")
- Don't explain what null or zero means for that column
- Don't state the unit for numeric fields (dollars vs cents)

Keep the tests unchanged. Only improve descriptions.
```

---

## Generate schema for multiple models at once

```
Generate complete schema entries for all models in [directory].

For each model:
- Read the SQL to understand the grain and columns
- Write a model description (grain, contents, when to use)
- Write column descriptions for ALL columns
- Add appropriate tests

Write everything to [yaml_file].
```

### Example — concrete version:

```
Generate complete schema entries for all models in models/intermediate/.

For each model:
- Read the SQL to understand the grain and columns
- Write a model description that explains WHY the intermediate exists
- Write column descriptions for ALL columns
- Add appropriate tests (unique + not_null on primary keys, relationships)

Write everything to models/intermediate/_int_models.yml.
```

---

## Audit existing tests for gaps

```
Look at all models in [directory] and their schema YAML files.

Identify:
1. Models with no tests at all
2. Primary keys missing unique or not_null tests
3. Foreign keys missing relationships tests
4. Status/category columns missing accepted_values tests
5. Amount columns missing >= 0 expression tests

List the gaps and then add the missing tests.
```

---

## Key principles for "test and document" prompts

1. **Ask for schema alongside build** — don't create models first and document later
2. **Be explicit about test types** — "unique + not_null on PK" is clearer than "appropriate tests"
3. **Let the docs skill handle quality** — if it's active, you don't need to say "don't write filler"
4. **Separate test additions from description rewrites** — two different prompts avoid Claude accidentally deleting tests while rewriting descriptions
5. **Audit periodically** — the "audit existing tests" prompt is useful as a health check on real projects
