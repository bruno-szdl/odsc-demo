# Prompts: Creating New Models

These prompts work best when you have the `project-style-guide` skill active.
They describe WHAT you want, not HOW to write it — the skill handles conventions.

---

## Create a staging model

```
Create a staging model for [source_table] in models/staging/.

The model should:
- Reference {{ source('[source_name]', '[table_name]') }}
- Rename columns to follow our conventions (snake_case, descriptive names)
- Cast dates and timestamps to the correct types
- Rename `id` to `[entity]_id`

Also add it to _stg_models.yml with column descriptions and tests
(unique + not_null on the primary key).
```

### Example — concrete version:

```
Create a staging model for the raw_products source table in models/staging/.

The model should:
- Reference {{ source('workshop', 'raw_products') }}
- Rename `id` to `product_id`
- Rename `cat` to `category`
- Cast `price` from integer cents to dollars (divide by 100, round to 2 decimals)
- Rename `created` to `created_at`

Also add it to _stg_models.yml with column descriptions and tests.
```

---

## Create an intermediate model

```
Create an intermediate model called [model_name] in models/intermediate/.

This model should [business purpose in plain language]:
- [column 1]: [how to calculate]
- [column 2]: [how to calculate]
- [column 3]: [how to calculate]

Create the SQL file and the schema YAML with:
- Model description explaining what it does and WHY it exists
- Column descriptions for all columns
- Tests: unique + not_null on [primary_key], relationships to [upstream_model]

Follow the CTE pattern and naming conventions in the existing models.
```

### Example — concrete version:

```
Create an intermediate model called int_order_payments in models/intermediate/.

This model should aggregate payment data at the order level from stg_payments:
- order_id (grouped by)
- total_amount: sum of amount
- payment_method_count: count of distinct payment methods
- payment_methods: comma-separated list of distinct payment methods used

Create the SQL file and the schema YAML with:
- Model description explaining what it does and why it exists
- Column descriptions for all columns
- Tests: unique + not_null on order_id, relationships to stg_orders

Follow the CTE pattern and naming conventions in the existing models.
```

---

## Create a mart model

```
Create a mart model called [model_name] in models/marts/.

This model represents [business entity]. One row per [grain].

It should include:
- [list of columns/metrics with business meaning]
- [which upstream models to use]

Use coalesce for any columns that could be null from left joins.
Also create the schema YAML entry with full descriptions and tests.
```

### Example — concrete version:

```
Create a mart model called products in models/marts/.

This model represents the product catalog. One row per product.

It should include:
- product_id, product_name, category (from stg_products)
- total_units_sold: count of order line items for this product (from stg_order_items)
- total_revenue: sum of line item amounts (from stg_order_items)
- first_sold_date, most_recent_sold_date

Use coalesce for products that have never been sold (zero for counts/amounts, null for dates).
Also create the schema YAML entry with full descriptions and tests.
```

---

## Key principles for "create" prompts

1. **Describe the WHAT, not the HOW** — let the style guide skill handle SQL patterns
2. **State the grain** — "one row per order", "one row per customer"
3. **List columns with business meaning** — "total amount spent", not "sum(amount)"
4. **Always ask for schema YAML together** — build and test in one step
5. **Mention upstream models explicitly** — "from stg_payments", "join through stg_orders"
