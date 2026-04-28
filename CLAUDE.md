# CLAUDE.md

This is a dbt project for a workshop on using Claude with dbt. It uses DuckDB as the warehouse — everything runs locally, no cloud credentials needed.

## Project layout

The dbt project lives in `dbt_project/`.

- Adapter: dbt-duckdb
- Profile: `dbt_project/profiles.yml` (path: `./workshop.duckdb`)
- Seeds: synthetic e-commerce data (customers, orders, payments)
- Staging: rename and cast only, materialized as views
- Intermediate: aggregations and joins, materialized as views
- Marts: final business entities, materialized as tables

## Running dbt

Prefer the MCP dbt tool (`mcp__dbt__build`, `mcp__dbt__run`, `mcp__dbt__test`, etc.) — it is configured automatically via `.mcp.json`, no setup needed.

For bash fallback, activate the project venv first — the system `dbt` lacks the duckdb adapter:

```bash
source .venv/bin/activate
cd dbt_project
dbt deps              # install packages (run once)
dbt seed              # load CSV seed data
dbt build             # run all models + tests
dbt run --select +model_name   # run a model and its upstream deps
dbt test --select model_name   # test a specific model
dbt compile --select model_name  # see compiled SQL without running
```

## Rules

- Never modify files in `seeds/` — those are source data
- Always run `dbt build` after making changes to validate
- Always generate schema YAML (descriptions + tests) alongside new models
- Never join a one-to-many table without aggregating first
- Use `ref()` for all model references — never hardcode table names

## Key data relationship

Orders and payments have a one-to-many relationship: one order can have multiple payments (split payments). Be mindful of cardinality when joining these entities.
