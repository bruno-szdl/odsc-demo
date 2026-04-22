# Prompts: Debugging

The most important pattern for debugging: **separate diagnosis from fix**.
Two prompts always produce better results than one "find and fix" prompt.

---

## Step 1: Diagnose the problem

Always start with diagnosis. Give Claude the symptom and evidence, then
ask it to explain — not fix.

```
[Model/test] has [symptom].

Evidence:
- [fact 1: row count, test failure message, wrong values]
- [fact 2: what you expected vs what you got]

Look at [file(s)] and explain:
1. What is causing this?
2. Why does it happen with our data?
3. What is the correct way to fix it?

Don't fix it yet — just explain the problem.
```

### Example — test failure:

```
The orders mart has a data quality issue. The unique test on order_id fails.

Evidence:
- The model has 55 rows but only 40 distinct order_ids
- Some orders appear multiple times with different payment information
- dbt build passes with no errors — only the test catches it

Look at models/marts/orders.sql and explain:
1. What is causing the duplication?
2. Why does this happen specifically with our data?
3. What is the correct way to fix it?

Don't fix it yet — just explain the problem.
```

### Example — wrong values:

```
The customers mart shows wrong lifetime_value for some customers.

Evidence:
- Customer 7 shows lifetime_value = 450.00
- But when I sum their payments manually, it should be 225.00
- It looks like some payments are being counted twice

Look at models/marts/customers.sql and the upstream models it references.
Explain what could cause payment amounts to be doubled.

Don't fix it yet — just explain the problem.
```

### Example — compilation error:

```
The model models/marts/orders.sql fails to compile with this error:

[paste the exact error message here]

Look at the SQL and explain what's wrong.
Don't fix it yet — just explain.
```

### Example — runtime error:

```
dbt run --select customers fails with this error:

[paste the exact error message here]

Look at models/marts/customers.sql and its upstream dependencies.
Explain what's causing the runtime error.
```

---

## Step 2: Fix the problem

After Claude explains the diagnosis, NOW ask for the fix.
Reference the diagnosis so Claude stays consistent.

```
Fix [model_path] based on the issue you just identified.

[Specific instructions for the fix, if you have preferences]

Follow the same CTE pattern used in the rest of the project.
[Any constraints: "don't change the grain", "keep existing columns"]
```

### Example — with existing intermediate:

```
Fix the orders mart model based on the fan-out issue you identified.

We already have int_order_payments that aggregates payments at the
order level. Use it instead of joining stg_payments directly.

Keep the same output grain (one row per order).
Follow the same CTE pattern used in the rest of the project.
Use coalesce for orders that might have no payments.
```

### Example — without existing intermediate:

```
Fix the orders mart model based on the duplication issue you identified.

Aggregate payments by order_id before joining:
- total_amount: sum of all payment amounts
- payment_method_count: count of distinct payment methods
- payment_methods: comma-separated list

Keep the existing order columns (order_id, customer_id, order_date, order_status).
Follow the same CTE pattern used in the rest of the project.
```

---

## Step 3: Validate the fix

After the fix, always validate. You can ask Claude to help.

```
Run the model and its tests to verify the fix:
1. dbt run --select [model]
2. dbt test --select [model]
3. Query the model to confirm [specific check]

Show me the results.
```

### Example — concrete version:

```
Run the orders model and its tests to verify the fix:
1. dbt run --select orders
2. dbt test --select orders
3. Query the model and show me the total row count and count of distinct order_ids

They should both be 40.
```

---

## Investigate data quality without a specific error

```
I want to check the data quality of [model].

Run these checks:
1. Total row count
2. Count of distinct [primary_key]
3. Check for nulls in [important_columns]
4. Distribution of [categorical_column]
5. Min, max, avg of [numeric_column]
6. Any [primary_key] values that appear more than once

Show me the results and flag anything unusual.
```

---

## Debug a failing dbt build

```
dbt build fails with the following output:

[paste the full error output]

Identify which model or test is failing and why.
If it's a SQL error, look at the compiled SQL in target/compiled/ to
understand what dbt generated.

Explain the root cause before suggesting a fix.
```

---

## Key principles for "debug" prompts

1. **Separate diagnosis from fix** — two prompts beat one every time
2. **Provide evidence** — row counts, error messages, expected vs actual values
3. **Say "don't fix yet"** — forces Claude to think before acting
4. **Reference the diagnosis in the fix prompt** — "based on the issue you identified"
5. **Always validate after fixing** — run model + tests + sanity check query
6. **Paste exact error messages** — don't paraphrase compiler/runtime errors
