---
name: meaningful-dbt-tests
description: >
  Use when writing, adding, or reviewing dbt tests in this project. Use this skill when someone asks to "add tests", "improve test coverage", or "make tests more comprehensive".
---

# Meaningful dbt Tests

Every test is a query. Every query has a cost — compute and, more importantly, human attention.
A test suite bloated with reflexive `not_null` checks on every column creates alert fatigue:
when everything fires, nothing gets investigated. The goal is tests that encode real business
expectations and that trigger specific, immediate action when they fail.

---

## The Action Step Test (Gate Before Writing Anything)

Before adding any test, answer this question:

> **"What specific action would I take immediately if this test failed?"**

If the answer is vague or you cannot name 1-2 concrete debugging steps, do not add the test
as an error. Either add it as a `warn` to gather signal, or backlog it until the remediation
path is clear.

```yaml
# ✅ Correct — clear remediation: investigate the upstream seed or ETL for the customer
- name: customer_id
  tests:
    - not_null   # Remediation: find which rows are missing and trace to the source

# ❌ Wrong — added because it seemed thorough, but what would you actually do if this failed?
- name: full_name
  tests:
    - dbt_utils.expression_is_true:
        arguments:
          expression: "length(full_name) > 1"
          # No clear remediation; should be a warn or removed until it matters
```

---

## Impact Classification: Error vs. Warn

After passing the Action Step gate, classify the test's severity using three questions:

| Question | If yes → |
|---|---|
| Is this output customer-facing? | `error` — fail the pipeline |
| Does it inform financial decisions? | `error` — fail the pipeline |
| Is it executive-facing? | `error` — fail the pipeline |
| None of the above | `warn` at most — or skip |

Set severity explicitly using the `config:` block when using warn:

```yaml
# ✅ Correct — warn severity: surfaces in test output but doesn't block pipeline
- name: total_orders
  tests:
    - dbt_utils.expression_is_true:
        arguments:
          expression: ">= 0"
        config:
          severity: warn   # Non-financial aggregate; warn until we see a real case
```

Default severity (no `config:` block) is `error`. Only omit `config:` when you mean it.

---

## Step 1: Inspect Before Testing

NEVER write tests for a model you have not sampled. Run `mcp__dbt__show` first to see actual
distributions, null rates, and value ranges. What you observe determines what you test.

```bash
mcp__dbt__show --select stg_payments --limit 20
mcp__dbt__show --select customers --limit 20
```

Questions to answer from the sample:

- Which columns are sometimes null? Are they *supposed* to be nullable?
- What are the actual distinct values for enum-like columns?
- What is the range for numeric columns — any negatives? Zeroes?
- Are string columns ever `''` rather than null?
- Do date columns ever violate expected ordering?

---

## Step 2: Three Test Buckets

Organize candidate tests into buckets. Work bucket 1 first; only move to bucket 2 if bucket 1
is solid and the tests pass the Action Step gate.

| Bucket | What it covers | Applied where |
|---|---|---|
| **Data Hygiene** | PKs, FKs, enum completeness, required fields | Staging layer — non-negotiable structural baseline |
| **Business Anomalies** | Domain-specific assertions: amount bounds, date ordering, row count parity | Marts — add only when failure has a clear remediation path |
| **Stats Anomalies** | Volume/distribution deviations | Out of scope for this skill — requires advanced tooling |

---

## Step 3: Column Classification and Required Tests

Classify each column before writing a single test. Only test what clears the Action Step gate.

### Primary Keys

Non-negotiable. Always error severity. Every PK gets both tests.

```yaml
# ✅ Correct
- name: customer_id
  tests:
    - not_null
    - unique
```

### Foreign Keys

`not_null` alone is insufficient. A valid-looking integer that references a nonexistent parent
is a data integrity failure. Always add `relationships`.

```yaml
# ✅ Correct — referential integrity enforced
- name: order_id
  tests:
    - not_null
    - relationships:
        arguments:
          to: ref('stg_orders')
          field: order_id

# ❌ Wrong — not_null alone cannot detect orphaned FK values
- name: order_id
  tests:
    - not_null
```

### Enum / Status Columns

`accepted_values` MUST be exhaustive — list every known value, not a sample. An exhaustive
list causes the test to catch new upstream values the moment they appear.

```yaml
# ✅ Correct — all five statuses; a sixth status added upstream will fail this test immediately
- name: order_status
  tests:
    - not_null
    - accepted_values:
        arguments:
          values: ["placed", "shipped", "completed", "return_pending", "returned"]

# ❌ Wrong — partial list; new upstream statuses silently pass
- name: order_status
  tests:
    - accepted_values:
        arguments:
          values: ["placed", "completed"]
```

### Numeric / Amount Columns

`not_null` does not verify the value makes sense. Add `dbt_utils.expression_is_true` for
range bounds — but only when you have a clear remediation step and know the severity.

**Column-scoped form** (expression references only this column):

```yaml
# ✅ Correct — amount_cents: negative value means sign error in the ETL calculation
- name: amount_cents
  tests:
    - not_null
    - dbt_utils.expression_is_true:
        arguments:
          expression: ">= 0"
          # Column name is prepended automatically: compiles to WHERE NOT (amount_cents >= 0)
          # Remediation: trace the payment record back to raw_payments and check the amount field

# ✅ Correct — amount (USD): derived from amount_cents; same rationale
- name: amount
  tests:
    - not_null
    - dbt_utils.expression_is_true:
        arguments:
          expression: ">= 0"
```

### Date Columns

Test `not_null` when the date is required. Temporal ordering invariants (e.g.,
`first_order_date <= most_recent_order_date`) are cross-column — use model-level tests
(see below), not column-level tests.

```yaml
# ✅ Correct — order_date is required on every order row
- name: order_date
  tests:
    - not_null
```

### String Columns

`not_null` does not catch empty strings. Add `dbt_utils.not_empty_string` only when an
empty value is genuinely invalid AND has a clear remediation (e.g., fix the source system).
Use `warn` severity until you confirm the remediation path.

```yaml
# ✅ Correct — email: empty string is as useless as null; unique because it's a natural key
- name: email
  tests:
    - not_null
    - unique
    - dbt_utils.not_empty_string:
        config:
          severity: warn   # Start as warn; escalate to error once you know your source system

# ❌ Wrong — not_empty_string added to every string column "just in case"
- name: first_name
  tests:
    - not_null
    - dbt_utils.not_empty_string   # Does your pipeline actually break if first_name is ''?
```

---

## Step 4: Model-Level Tests (Selective)

Add model-level tests only for high-impact invariants — not to maximize coverage. A model-level
test goes in the `tests:` block at the model level, before `columns:`.

### Cross-Column Invariants: `expression_is_true` (model-scoped)

Use when a violation would indicate a model logic bug worth pipeline failure.

```yaml
# ✅ Correct — customers mart: first_order_date must not exceed most_recent_order_date
# Note: add a null guard when date columns are nullable (customers with no orders have null dates)
models:
  - name: customers
    tests:
      - dbt_utils.expression_is_true:
          arguments:
            expression: "first_order_date is null or first_order_date <= most_recent_order_date"
            # Remediation: a violation means min/max are swapped in the customer_orders CTE
    columns:
      ...
```

### Row Count Parity: `equal_rowcount`

Use when a mart model must be exactly 1:1 with a staging model — fan-out from a join bug
would silently corrupt all aggregated metrics.

```yaml
# ✅ Correct — customers mart must have exactly one row per stg_customers row
models:
  - name: customers
    tests:
      - dbt_utils.equal_rowcount:
          arguments:
            compare_model: ref('stg_customers')
            # Remediation: the left join to customer_orders has introduced a fan-out
```

### Composite Uniqueness: `unique_combination_of_columns`

Use when there is no single-column PK but the model must be unique on a combination.

```yaml
# ✅ When applicable — unique per (order_id, payment_method) combination
- dbt_utils.unique_combination_of_columns:
    arguments:
      combination_of_columns:
        - order_id
        - payment_method
```

---

## dbt_utils Syntax Reference

dbt_utils tests wrap parameters under `arguments:`. The `config:` block is a sibling of
`arguments:`, not nested inside it.

```yaml
# Full structure showing both arguments and config
- dbt_utils.expression_is_true:
    arguments:
      expression: ">= 0"
    config:
      severity: warn
```

**Column-scoped `expression_is_true`** — inside a `column` block; dbt_utils prepends the
column name automatically. Write only the operator and value, NOT the column name:

```yaml
# ✅ Correct — dbt_utils compiles this to: WHERE NOT (amount >= 0)
- name: amount
  tests:
    - dbt_utils.expression_is_true:
        arguments:
          expression: ">= 0"

# ❌ Wrong — dbt_utils prepends the column name, producing: WHERE NOT (amount amount >= 0)
- name: amount
  tests:
    - dbt_utils.expression_is_true:
        arguments:
          expression: "amount >= 0"
```

**Model-scoped `expression_is_true`** — inside the model's `tests:` block; expression is
evaluated as written. Use the full expression including column names. Add null guards for
nullable columns to avoid false failures:

```yaml
tests:
  - dbt_utils.expression_is_true:
      arguments:
        expression: "first_order_date is null or first_order_date <= most_recent_order_date"
        # Null guard required: customers with no orders have null dates; NULL <= NULL is NULL,
        # which would be treated as a test failure without the guard
```

---

## What NOT to Test

Explicitly skipping tests is as important as adding them.

- **Don't add `not_null` to intentionally nullable columns** — `first_order_date` and
  `most_recent_order_date` in `customers` are null for customers with no orders; testing
  `not_null` would fail on every new customer before their first purchase.
- **Don't test string length or format** (email regex, name length) unless you have a
  production incident caused by that specific violation.
- **Don't add `not_empty_string` to every string column** — only where an empty value is
  genuinely invalid and you know what you'd do to fix it.
- **Don't add range tests "just in case"** — add them when you can name the upstream system
  that would produce the violation and who to notify.
- **Don't duplicate tests across staging and marts** — test data fidelity in staging; test
  business logic in marts. A FK `relationships` test belongs in staging, not the mart.

---

## Step 5: Run and Interpret

After adding tests, always run them before considering the task complete.

```bash
mcp__dbt__test --select stg_payments
mcp__dbt__test --select marts
mcp__dbt__test
```

A failing test is a discovery, not a mistake. It means one of two things:

1. **Real data problem** — the source data violates an assumption. Trace the failing rows,
   identify the upstream cause, and either fix the source or add a filter/coalesce in the model.
2. **Wrong assumption** — the test was too strict. Adjust it to match reality and add a YAML
   comment explaining why. Then ask whether the original business rule was wrong or whether
   the data is the problem.

NEVER delete a failing test without understanding why it failed.

---

## Decision Checklist

Before adding each individual test, verify:

- [ ] I can name the specific action I'd take immediately if this test fails
- [ ] I've classified this output's impact: customer-facing, financial, or executive-facing?
- [ ] I've set severity to `error` only for high-impact failures; `warn` otherwise
- [ ] I've sampled the model with `mcp__dbt__show` and confirmed the test reflects real data
- [ ] I'm testing this column because it matters, not because it exists

---

## What This Skill Does Not Cover

- SQL style, CTE structure, and model formatting — see `project-style-guide`
- How to write column and model descriptions — see `documentation-quality`
- Stats-based anomaly detection (volume spikes, distribution drift) — advanced tooling required
