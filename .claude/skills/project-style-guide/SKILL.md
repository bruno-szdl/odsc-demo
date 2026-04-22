---
name: project-style-guide
description: >
  Use when creating, modifying, or reviewing any SQL model or dbt resource
  in this project. Always use this skill when writing new models, refactoring
  existing ones, adding columns, structuring CTEs, choosing materializations,
  or joining tables. This skill covers SQL patterns, formatting, folder
  structure, and the aggregation rule. For naming conventions and documentation
  standards, see the documentation-quality skill.
---

# Project Style Guide

This skill defines the SQL patterns, formatting rules, and structural conventions
for this project. For naming conventions (models, columns, files) and documentation
quality standards, see the `documentation-quality` skill.

## CTE Pattern

Every model MUST follow this exact structure, in order:

1. **Import CTEs** — one per `ref()` or `source()`, named after the entity
2. **Transformation CTEs** — descriptive names: `aggregated`, `filtered`, `renamed`, `joined`
3. **Final CTE** — always called `final`
4. **Closing select** — always `select * from final`

Never skip the final CTE. Never put transformation logic inside an import CTE.

```sql
-- ✅ CORRECT pattern
with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

aggregated as (
    select
        customer_id,
        count(order_id) as number_of_orders,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date
    from orders
    group by customer_id
),

final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customers.email,
        coalesce(aggregated.number_of_orders, 0) as number_of_orders,
        aggregated.first_order_date,
        aggregated.most_recent_order_date
    from customers
    left join aggregated on customers.customer_id = aggregated.customer_id
)

select * from final
```

```sql
-- ❌ WRONG — transformation logic inside import CTE
with customers as (
    select
        id as customer_id,
        first_name,
        last_name,
        count(*) as order_count
    from {{ ref('stg_customers') }}
    join {{ ref('stg_orders') }} using (customer_id)
    group by 1, 2, 3
)

select * from customers
```

## SQL Formatting

- **Lowercase** for all SQL keywords: `select`, `from`, `where`, `group by`, `left join`
- **4-space indentation** — not tabs, not 2 spaces
- **Trailing commas** — comma at the end of the line, not the beginning
- **One column per line** in `select` statements
- **Explicit aliases** — always use `as`: write `count(order_id) as number_of_orders`
- **Qualify columns with full CTE name** when joining: `orders.customer_id`, not bare `customer_id`. Never use single-letter aliases like `c` or `o`.
- **Coalesce left joins** — always use `coalesce()` for columns from left joins that could return null
- **No `select *`** except in import CTEs and the final `select * from final`
- **`left join` by default** — only use `inner join` when you intentionally want to exclude rows
- **`group by` column names** — not positional numbers

## Materializations

| Layer | Materialization |
|-------|----------------|
| Staging | `view` |
| Intermediate | `view` |
| Marts | `table` |

## The Aggregation Rule

**NEVER join a table with a one-to-many relationship without aggregating first.**

This is the single most important rule in this project. When a table has multiple rows per key (e.g., line items per invoice, reviews per product, transactions per account), you MUST aggregate in a separate CTE or intermediate model BEFORE joining. A direct join creates row duplication (fan-out).

```sql
-- ✅ CORRECT: aggregate the many-side first, then join
product_reviews as (
    select
        product_id,
        count(*) as number_of_reviews,
        avg(rating) as average_rating
    from reviews
    group by product_id
),

final as (
    select
        products.product_id,
        products.product_name,
        coalesce(product_reviews.number_of_reviews, 0) as number_of_reviews,
        product_reviews.average_rating
    from products
    left join product_reviews on products.product_id = product_reviews.product_id
)
```

```sql
-- ❌ WRONG: direct join creates duplicates
final as (
    select
        products.product_id,
        products.product_name,
        reviews.rating
    from products
    left join reviews on products.product_id = reviews.product_id
)
-- A product with 5 reviews produces 5 rows instead of 1
```

If the same aggregation is needed by more than one mart, extract it into an **intermediate model** rather than repeating the logic.

## Folder Structure

```
models/
├── staging/          # 1:1 with sources. Rename and cast only. No joins, no aggregations.
│   ├── _stg_sources.yml
│   ├── _stg_models.yml
│   └── stg_*.sql
├── intermediate/     # Aggregation, multi-source joins, business logic prep.
│   ├── _int_models.yml
│   └── int_*.sql
└── marts/            # Final business entities. One row per grain. What analysts query.
    ├── _marts_models.yml
    └── *.sql
```

Rules:
- Staging models do NOT contain business logic, joins, or aggregations
- Intermediate models prepare data for marts — aggregations, multi-source joins, logic that serves more than one mart
- Marts are the final layer — they define the grain and are what analysts query
- Each layer has its own schema YAML file prefixed with `_`
- Schema files: `_<layer>_models.yml`
- Source files: `_<layer>_sources.yml`

## Data Domain Context

This project models a simple e-commerce business:

- **Customers** — people with accounts (may or may not have ordered)
- **Orders** — purchases with a lifecycle status: placed → shipped → completed or returned
- **Payments** — individual payment transactions. **One order can have multiple payments** (split payments with different methods)

Be aware of the cardinality between these entities when joining them — apply the aggregation rule above wherever a one-to-many relationship exists.