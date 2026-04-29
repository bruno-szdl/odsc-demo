---
name: documentation-quality
description: >
  Use when writing, generating, or reviewing descriptions in YAML schema files, including model
  descriptions and column descriptions. Also use when naming new models, columns, or files. Always use this skill when creating or updating schema.yml files, adding documentation to models, writing column descriptions, or when someone asks to improve or generate dbt documentation.
---

# Documentation Quality Standards

This skill defines naming conventions, documentation quality standards, and test annotation
patterns for this project. It is the source of truth for how to name models, columns, and files,
and how to write descriptions that are genuinely useful. For SQL patterns, CTE structure, and
formatting rules, see the `project-style-guide` skill.

The core principle: if a description just restates the column name, it is filler and must be rewritten.

---

## Model File Naming Standards

SQL model files must follow the layer prefix convention. The filename determines how dbt resolves
`ref()` and how analysts discover models, so names must be self-describing.

| Layer | File pattern | Example |
|-------|-------------|---------|
| Staging | `stg_<source>_<entity>.sql` or `stg_<entity>.sql` | `stg_customers.sql`, `stg_stripe_payments.sql` |
| Intermediate | `int_<entity>_<verb>.sql` | `int_order_payments_aggregated.sql` |
| Marts | `<entity>.sql` — plain business noun, no prefix | `customers.sql`, `orders.sql` |

Rules:
- All lowercase, words separated by underscores — never camelCase or hyphens
- Use the plural noun form for the entity (`customers`, not `customer`)
- Intermediate names must include a verb or purpose (`aggregated`, `pivoted`, `joined`) — never just `int_orders`
- Never abbreviate source names — `stg_salesforce_accounts` not `stg_sf_accts`
- Never number models — `customers_v2` or `customers_2` is a signal to version properly or merge

---

## Column Naming Standards

Column names must be self-describing without requiring a description to understand type or role.
The name encodes the semantic type; the description then adds business context and edge cases.

| Semantic type | Naming pattern | Examples | Anti-patterns |
|---------------|---------------|----------|---------------|
| Primary key | `<entity_singular>_id` | `customer_id`, `order_id` | `id`, `pk`, `cust_id` |
| Foreign key | **identical** to the PK it references | `customer_id` in orders table | `cust_fk`, `customer`, `customer_key` |
| Surrogate key | `<entity_singular>_key` | `customer_key` | `sk`, `surrogate_id` |
| Natural/business key | `<entity_singular>_<source>_id` | `customer_salesforce_id` | `sf_id`, `external_id` |
| Date (date only) | `<event>_date` | `order_date`, `first_order_date` | `order_dt`, `dt_order`, `ordered` |
| Timestamp (datetime) | `<event>_at` | `created_at`, `updated_at`, `shipped_at` | `create_ts`, `creation_timestamp`, `ts_created` |
| Boolean | `is_<condition>` or `has_<condition>` | `is_active`, `has_returns` | `active_flag`, `returned`, `active` |
| Count | `number_of_<entity_plural>` | `number_of_orders`, `number_of_payments` | `order_count`, `num_orders`, `cnt` |
| Distinct count | `<entity_singular>_count` | `payment_method_count` | `num_methods`, `cnt_pm` |
| Monetary amount | descriptive noun, never bare `amount` | `lifetime_value`, `total_amount`, `refund_amount` | `amount`, `amt`, `val` |
| Aggregated list | `<entity_plural>` | `payment_methods`, `product_categories` | `method_list`, `pm_agg`, `cats` |
| Percentage / ratio | `<metric>_pct` or `<metric>_rate` | `return_rate`, `discount_pct` | `rate`, `pct`, `percent_returned` |
| Currency unit | state the unit in the description, not the name | column: `total_amount`, description says "in USD" | `total_amount_usd` (redundant in name) |
| Duration | `<entity>_<unit>s` or `days_since_<event>` | `session_seconds`, `days_since_last_order` | `duration`, `time_diff`, `elapsed` |

### ID column rules

- Every model must have exactly one primary key column named `<entity_singular>_id`
- Foreign keys must use the **exact same name** as the PK in the referenced model — if the customers mart PK is `customer_id`, then every model that references it must also call it `customer_id`
- When two foreign keys of the same type appear in one model (e.g., `sender_id` and `recipient_id` both referencing users), prefix with the role: `<role>_<entity_id>` — e.g., `sender_user_id`, `recipient_user_id`

---

## Doc Blocks: Descriptions in `.md` Files

All model and column descriptions longer than one short sentence **must** live in a `.md` file
and be referenced from the YAML with the `{{ doc() }}` macro. This keeps YAML readable and
allows descriptions to be reused across models.

### File structure

Every model's doc block file must have the **exact same base name** as its `.sql` file, placed
in the same directory:

```
models/
├── staging/
│   ├── stg_customers.sql
│   ├── stg_customers.md       ← doc blocks for stg_customers
│   ├── stg_orders.sql
│   ├── stg_orders.md
│   └── _stg_models.yml
└── marts/
    ├── customers.sql
    ├── customers.md           ← doc blocks for customers
    ├── orders.sql
    ├── orders.md
    └── _marts_models.yml
```

### Writing `.md` doc block files

Each block uses the `{% docs <name> %}` / `{% enddocs %}` syntax. The name must be globally
unique across the project — use the pattern `<model_name>__<column_name>` for columns, and
`<model_name>` for model-level descriptions:

```markdown
{% docs customers %}
One row per customer who has created an account. Includes profile information
(name, email), order history metrics (first and last order dates, total order
count), and lifetime payment data. This is the primary customer dimension —
use it for customer-level aggregates. For order-level detail, use the orders
mart instead.
{% enddocs %}

{% docs customers__customer_id %}
Unique identifier for each customer, assigned at account registration.
Serves as the primary key for this model.
{% enddocs %}

{% docs customers__first_order_date %}
Date of the customer's earliest order, regardless of order status. Null for
customers who registered but never placed an order.
{% enddocs %}

{% docs customers__total_orders %}
Total number of orders placed by this customer across all statuses (placed,
shipped, completed, returned). Zero for customers who registered but never
ordered — never null.
{% enddocs %}
```

### Referencing doc blocks in YAML

In the `.yml` schema file, replace inline strings with `{{ doc("<name>") }}`:

```yaml
# ✅ Correct — descriptions live in .md, YAML stays clean
models:
  - name: customers
    description: "{{ doc('customers') }}"
    columns:
      - name: customer_id
        description: "{{ doc('customers__customer_id') }}"
        tests:
          - not_null  # Every row must represent a real customer
          - unique    # Duplicates indicate a fan-out join bug
      - name: first_order_date
        description: "{{ doc('customers__first_order_date') }}"
      - name: total_orders
        description: "{{ doc('customers__total_orders') }}"
```

```yaml
# ❌ Wrong — long descriptions inlined in YAML
models:
  - name: customers
    description: >
      One row per customer who has created an account. Includes profile
      information (name, email), order history metrics...
```

Short descriptions (under ~15 words, no multi-sentence context needed) may be inlined directly
in YAML as a plain string — no `.md` file required for those.

---

## Model Descriptions

Every model description must answer three questions:

1. **What** — what business entity or concept does this model represent?
2. **Grain** — what does one row represent? Be explicit.
3. **When to use** — when should someone query this model instead of another?

### Bad Examples (Never Do This)

```yaml
# ❌ Restates the model name
- name: customers
  description: "Customer data."

# ❌ Adds words but no information
- name: customers
  description: "Customer data from the e-commerce platform."

# ❌ Generic filler
- name: orders
  description: "This model contains order information."

# ❌ Too vague to be useful
- name: int_order_payments
  description: "Intermediate model for order payments."
```

### Good Examples (use `{{ doc() }}` for these)

```markdown
{% docs customers %}
One row per customer who has created an account. Includes profile
information (name, email), order history metrics (first and last
order dates, total order count), and lifetime payment data (total
spend, payment methods used). This is the primary customer
dimension — use it for customer-level aggregates. For order-level
detail, use the orders mart instead.
{% enddocs %}

{% docs orders %}
One row per order placed on the platform. Combines order metadata
(date, status) with aggregated payment information (total amount,
payment methods). Use this for order-level analysis. For
customer-level rollups, use the customers mart.
{% enddocs %}

{% docs int_order_payments %}
Aggregates payment data at the order level. One row per order_id.
Sums payment amounts and collects distinct payment methods. This
intermediate exists to prevent fan-out when joining payments to
orders or customers — always use this model instead of joining
stg_payments directly.
{% enddocs %}
```

---

## Column Descriptions

Every column description must provide at least one of:

1. **Business meaning** — what it represents, not just the technical name
2. **Source or lineage** — where it comes from if not obvious
3. **Edge cases** — what null, zero, or unexpected values mean

### Filler Patterns to NEVER Use

| Column | Bad Description | Problem |
|--------|----------------|---------|
| `customer_id` | "The ID of the customer" | Restates the name |
| `email` | "The customer's email" | Adds zero information |
| `first_order_date` | "The date of the first order" | No context about nulls |
| `lifetime_value` | "The lifetime value" | Column name with spaces |
| `order_status` | "The status of the order" | No info about possible values |
| `total_amount` | "The total amount" | Total of what? In what unit? |
| `payment_method` | "The payment method used" | Which one if there are multiple? |
| `number_of_orders` | "The number of orders" | Does not explain what counts |

### Good Description Patterns by Column Type

#### Identifiers

```markdown
{% docs orders__order_id %}
Unique identifier for each order. Assigned when the order is first placed
and persists through all status changes.
{% enddocs %}

{% docs orders__customer_id %}
Foreign key to the customers mart. Identifies which customer placed this
order. Never null — every order must belong to a known customer.
{% enddocs %}
```

#### Dates and Timestamps

```markdown
{% docs customers__first_order_date %}
Date of the customer's earliest order, regardless of order status. Null
for customers who registered but never placed an order.
{% enddocs %}

{% docs customers__most_recent_order_date %}
Date of the customer's most recent order, regardless of status. Null for
customers with no orders. Compare with first_order_date to calculate
customer tenure.
{% enddocs %}

{% docs orders__order_date %}
Date when the order was originally placed. Does not change when the order
status is updated later.
{% enddocs %}

{% docs orders__created_at %}
Timestamp (UTC) when the order record was first inserted into the source
system. Distinct from order_date, which reflects the business event date.
{% enddocs %}
```

#### Amounts and Financial Data

```markdown
{% docs customers__lifetime_value %}
Total amount spent by the customer across all orders, in dollars. Includes
all order statuses (completed, returned, pending). Zero for customers who
have never placed an order — never null.
{% enddocs %}

{% docs orders__total_amount %}
Sum of all payment amounts for this order, in dollars. An order paid with
two methods (e.g., gift card + credit card) shows the combined total. Zero
if no payments are recorded.
{% enddocs %}
```

#### Counts

```markdown
{% docs customers__number_of_orders %}
Total count of orders placed by this customer, regardless of status.
Includes completed, returned, and pending orders. Zero for customers who
registered but never ordered — never null.
{% enddocs %}
```

#### Status and Categorical Fields

```markdown
{% docs orders__status %}
Current lifecycle status of the order. Possible values:
- 'placed': order created, not yet shipped
- 'shipped': order in transit
- 'completed': order delivered
- 'return_pending': return requested by customer
- 'returned': return processed
Orders generally move through these statuses in sequence.
{% enddocs %}

{% docs payments__payment_method %}
Method used for this individual payment. Possible values: 'credit_card',
'bank_transfer', 'gift_card', 'coupon'. One order may have multiple
payments with different methods.
{% enddocs %}
```

---

## Test Annotations

When adding tests, include a brief YAML comment explaining WHY the test exists:

```yaml
columns:
  - name: order_id
    description: "{{ doc('orders__order_id') }}"
    tests:
      - unique    # Duplicates indicate a fan-out join upstream
      - not_null  # Every row must represent a real order
  - name: customer_id
    tests:
      - not_null
      - relationships:
          arguments:
            to: ref('stg_customers')
            field: customer_id
            # Ensures every order belongs to a known customer
  - name: status
    tests:
      - accepted_values:
          arguments:
            values: ['placed', 'shipped', 'completed', 'return_pending', 'returned']
            # Catches unexpected status values introduced upstream
  - name: lifetime_value
    tests:
      - dbt_utils.expression_is_true:
          arguments:
            expression: ">= 0"
            # Negative lifetime value indicates a calculation error
```

---

## Writing Process

When generating or updating schema YAML, follow this order:

1. **Read the SQL** — understand what the model does, what it joins, what it aggregates
2. **Identify the grain** — what does one row represent?
3. **Write `.md` doc blocks first** — model description (grain, contents, when to use), then each column
4. **Reference from YAML** — use `{{ doc('<name>') }}` in the schema file
5. **Check for filler** — re-read every description; if it restates the column name, rewrite it
6. **Add null/zero context** — for every column from a left join or aggregation, state what null or zero means
7. **State units** — every numeric column must say what unit it is in (dollars, cents, count)

---

## Quality Checklist

Before finalizing any schema YAML, verify every item:

- [ ] Every `.md` doc block file has the same base name as its `.sql` file
- [ ] Every model description is in a `{% docs %}` block (if more than ~15 words)
- [ ] Every model description states the grain ("one row per...")
- [ ] Every model description says when to use it vs. alternatives
- [ ] Every column description adds information beyond the column name
- [ ] Every nullable column explains what null means in business terms
- [ ] Every numeric column states the unit (dollars, cents, count)
- [ ] Every primary key has `unique` + `not_null` tests
- [ ] Every foreign key has a `relationships` test
- [ ] Every status/category column has `accepted_values`
- [ ] No description is shorter than 10 words
- [ ] No description is just the column name with spaces added