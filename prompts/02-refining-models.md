# Prompts: Refining and Modifying Models

These prompts are for when the model already exists and you need to change it.
The key pattern: **anchor what to keep**, then describe what to add or change.

---

## Add columns to an existing model

```
Enhance [model_path] to include [new columns/metrics].

Use [upstream model] to calculate:
- [column_name]: [business definition]
- [column_name]: [business definition]

Keep all existing columns.
Use coalesce for values that could be null from left joins.
Follow the same CTE pattern already in the file.
Also update [schema_yaml_path] with descriptions and tests for the new columns.
```

### Example — concrete version:

```
Enhance models/marts/customers.sql to include payment metrics.

Use int_order_payments joined through stg_orders to calculate:
- lifetime_value: total amount spent by the customer across all orders
- payment_method_count: number of distinct payment methods used

Keep all existing columns.
Use coalesce for customers with no orders (zero for amounts and counts).
Follow the same CTE pattern already in the file.
Also update _marts_models.yml with descriptions and tests for the new columns.
```

---

## Refactor a model to use an intermediate

```
Refactor [model_path] to use [intermediate_model] instead of [direct_reference].

Currently it [describe current behavior and why it's a problem].

Replace the [problematic pattern] with a reference to [intermediate_model].
Keep the same output columns and grain.
Follow the same CTE pattern used in the rest of the project.
```

### Example — concrete version:

```
Refactor models/marts/orders.sql to use int_order_payments instead of
joining stg_payments directly.

Currently it joins stg_payments without aggregating, which creates
duplicate rows for orders with multiple payments.

Replace the direct join with a reference to int_order_payments.
Keep the same output grain (one row per order).
Follow the same CTE pattern used in the rest of the project.
```

---

## Change a column's logic

```
In [model_path], change how [column_name] is calculated.

Currently: [what it does now]
Should be: [what it should do instead]

Reason: [why the change is needed]

Only change this specific column. Keep everything else the same.
Update the column description in [schema_yaml] if the meaning changed.
```

### Example — concrete version:

```
In models/marts/customers.sql, change how lifetime_value is calculated.

Currently: sums all payment amounts regardless of order status.
Should be: only sum payments from orders with status = 'completed'.

Reason: returned orders should not count toward lifetime value.

Only change this specific column. Keep everything else the same.
Update the column description in _marts_models.yml to reflect this filter.
```

---

## Add a filter or business rule

```
In [model_path], add a filter to [describe what to filter].

The filter should: [exact condition]
Apply it in: [which CTE or step]

Do not change the output columns or grain.
Add a comment in the SQL explaining why the filter exists.
```

### Example — concrete version:

```
In models/marts/orders.sql, add a filter to exclude test orders.

The filter should: exclude orders where customer_id = 0
Apply it in: the import CTE for orders (filter early)

Do not change the output columns or grain.
Add a comment in the SQL explaining why the filter exists.
```

---

## Key principles for "refine" prompts

1. **Anchor what to keep** — "Keep all existing columns", "Keep the same grain"
2. **Be specific about the change** — "currently X, should be Y"
3. **State the reason** — helps Claude make better decisions about edge cases
4. **Ask for schema updates together** — if columns changed, descriptions should too
5. **One change per prompt** — refactoring + adding columns + changing logic in one prompt produces worse output than three separate prompts
