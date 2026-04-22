# Build, Test, and Debug dbt Faster with Claude

Sample dbt project for the ODSC East workshop by Bruno Souza de Lima.

This project uses **DuckDB** as the warehouse — no cloud account or credentials needed. Everything runs locally.

---

## Prerequisites

**macOS**

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install python git node
brew install --cask visual-studio-code

pip install dbt-core dbt-duckdb uv
npm install -g @anthropic-ai/claude-code
```

**Windows**

```powershell
# Install winget if you don't have it (comes with Windows 11; search "App Installer" in the Microsoft Store for Windows 10)

winget install Python.Python.3.11
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Microsoft.VisualStudioCode

pip install dbt-core dbt-duckdb uv
npm install -g @anthropic-ai/claude-code
```

You will also need a **Claude account** with Claude Code access (claude.ai Pro or an Anthropic API key). Sign up at https://claude.ai before the session.

---

## Setup

```bash
# 1. Clone the repo
git clone https://github.com/<your-handle>/odsc-demo.git
cd odsc-demo

# 2. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# 3. Install dbt with DuckDB adapter and uv (needed for the dbt MCP server)
pip install dbt-core dbt-duckdb uv

# 4. Verify
dbt --version

# 5. Move into the dbt project folder
cd dbt_claude_workshop

# 6. Install dbt packages
dbt deps

# 7. Load seed data
dbt seed

# 8. Build all models and run tests
dbt build
```

Running `dbt build` will create a local `workshop.duckdb` file with all seeds loaded, models materialized, and staging tests executed.

---

## Project Structure

```
odsc-demo/
├── README.md
├── TOOLKIT.md                      # Reference guide: how to use Claude with dbt
├── .mcp.json                       # dbt MCP server config for Claude Code
├── .claude/
│   └── skills/                     # Project-specific Claude skills
│       ├── project-style-guide/
│       │   └── SKILL.md
│       └── documentation-quality/
│           └── SKILL.md
├── prompts/                        # Reusable prompt examples by task type
│   ├── 01-creating-models.md
│   ├── 02-refining-models.md
│   ├── 03-tests-and-docs.md
│   ├── 04-debugging.md
│   └── 05-exploring-project.md
├── dbt_claude_workshop/            # dbt project lives here
│   ├── dbt_project.yml
│   ├── profiles.yml                # DuckDB local connection
│   ├── packages.yml
│   ├── seeds/
│   │   ├── raw_customers.csv       # 15 sample customers
│   │   ├── raw_orders.csv          # 40 sample orders
│   │   └── raw_payments.csv        # 55 payments (some orders have multiple)
│   └── models/
│       ├── staging/
│       │   ├── _stg_sources.yml    # source definitions
│       │   ├── _stg_models.yml     # tests + documentation
│       │   ├── stg_customers.sql
│       │   ├── stg_orders.sql
│       │   └── stg_payments.sql
│       └── marts/
│           ├── _marts_models.yml   # minimal model definitions (no tests yet)
│           ├── customers.sql       # customer summary — intentionally incomplete
│           └── orders.sql          # order + payment join — intentional bug
```

Staging models are materialized as **views**. Mart models are materialized as **tables**.

---

## Connecting Claude Code (dbt MCP)

The `.mcp.json` file in this repo configures the dbt MCP server for Claude Code. Once you have `uvx` available (`pip install uv`), Claude Code will automatically pick it up when you open this project.

Before starting Claude Code, copy `.env.example` to `.env` and set both variables:

```bash
cp .env.example .env
```

| Variable | What to set |
|----------|-------------|
| `DBT_PATH` | Path to your dbt executable — run `which dbt` (macOS/Linux) or `where dbt` (Windows) after activating your venv |
| `DBT_PROJECT_DIR` | Path to the dbt project folder — `./dbt_project` (default, no change needed) |

---

## Installing the dbt Agent Skills

The [dbt Agent Skills](https://github.com/dbt-labs/dbt-agent-skills) are official skills from dbt Labs that give Claude Code deep knowledge of dbt workflows — building models, writing tests, running commands, troubleshooting errors, and more.

Install them once via the Claude Code CLI:

```bash
# Add the dbt Labs skills marketplace
claude plugin marketplace add dbt-labs/dbt-agent-skills

# Install the dbt analytics engineering skills
claude plugin install dbt@dbt-agent-marketplace
```

The skills activate automatically when Claude detects dbt-related work — no manual invocation needed.

---

## Toolkit: What You Need to Use Claude Well with dbt

### Layer 1 — The Minimum (5 min setup)

**dbt MCP Server** — gives Claude visibility into your project structure, models, lineage, and configs. Without it, Claude sees your project as a folder of text files. The `.mcp.json` in this repo handles this.

**CLAUDE.md** — a file at the project root that Claude Code loads automatically every session. Put things here that are always true: adapter, common commands, rules. Keep it short.

### Layer 2 — Quality Multiplier (30 min setup)

**dbt Agent Skills (official)** — generic dbt best practices maintained by dbt Labs. Teaches Claude the workflow: discover → build → test → verify.

**Project-specific skills** — where you put YOUR project's rules. This repo includes two:

| Skill | What it answers | Location |
|-------|----------------|----------|
| `project-style-guide` | "How do we do things here?" — naming, CTE pattern, materializations, aggregation rule | `.claude/skills/project-style-guide/SKILL.md` |
| `documentation-quality` | "What does useful documentation look like?" — no filler, state the grain, explain nulls | `.claude/skills/documentation-quality/SKILL.md` |

### Layer 3 — Prompt Patterns (zero setup, it's practice)

See the full prompt library in `prompts/` or the quick reference below.

---

## Prompt Quick Reference

### Creating models — describe the WHAT, not the HOW

```
Create [model name] in [path]. It should [business description].
Follow the CTE pattern in the existing models.
Also create/update the schema YAML with descriptions and tests.
```

**Example:**

```
Create an intermediate model called int_order_payments in models/intermediate/.

This model should aggregate payment data at the order level from stg_payments:
- order_id (grouped by)
- total_amount: sum of amount
- payment_method_count: count of distinct payment methods
- payment_methods: comma-separated list of distinct payment methods used

Create the SQL file and the schema YAML with model description,
column descriptions, and tests (unique + not_null on order_id,
relationships to stg_orders).

Follow the CTE pattern and naming conventions in the existing models.
```

### Refining models — anchor what to keep

```
Enhance [model] to include [new columns/logic].
Use [existing model] for [data source].
Keep existing columns. Use coalesce for nulls.
Follow the same CTE pattern already in the file.
Also update [schema YAML] with descriptions and tests for the new columns.
```

**Example:**

```
Enhance models/marts/customers.sql to include payment metrics.

Use int_order_payments joined through stg_orders to calculate:
- lifetime_value: total amount spent by the customer across all orders
- payment_method_count: number of distinct payment methods used

Keep all existing columns. Use coalesce for customers with no orders.
Follow the same CTE pattern already in the file.
Also update _marts_models.yml with descriptions and tests for the new columns.
```

### Debugging — always separate diagnosis from fix

**Step 1 — Diagnose:**

```
[Model] has [symptom]. [Evidence: row count, error, wrong values].
Look at [file] and explain what is causing this.
Don't fix it yet — just explain the problem.
```

**Example:**

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

**Step 2 — Fix (separate prompt):**

```
Fix [model] based on the issue you identified.
[Specific constraints or preferences].
Follow the same CTE pattern used in the rest of the project.
```

**Example:**

```
Fix the orders mart model based on the fan-out issue you identified.

We already have int_order_payments that aggregates payments at the
order level. Use it instead of joining stg_payments directly.

Keep the same output grain (one row per order).
Follow the same CTE pattern used in the rest of the project.
Use coalesce for orders that might have no payments.
```

**Step 3 — Validate:**

```
Run the model and its tests to verify the fix:
1. dbt run --select orders
2. dbt test --select orders
3. Query the model and show me the total row count and count of distinct order_ids
```

### Tests and documentation — ask alongside build

```
Add a complete schema entry for [model] in [yaml file].
Include model description (grain, contents, when to use),
column descriptions for ALL columns, and appropriate tests.
```

**Example:**

```
Add a complete schema entry for the orders model in _marts_models.yml.

Include:
- Model description (grain: one row per order, what it contains, when to use)
- Column descriptions for ALL columns
- Tests: unique + not_null on order_id, not_null on customer_id,
  accepted_values on order_status, relationships for customer_id,
  expression test total_amount >= 0
```

### Exploring a project — understand before you change

```
Look at [model_path] and explain:
1. What does this model do? (grain, purpose)
2. What are its upstream dependencies?
3. What are the key business rules?
4. Are there any potential issues?
Keep the explanation concise.
```

**Example:**

```
Look at models/marts/customers.sql and explain:
1. What does this model do?
2. What upstream models does it depend on?
3. What metrics does it calculate?
4. What's missing or could be improved?
Keep the explanation concise — I want to understand it in 2 minutes.
```

### Data profiling — know your data before building

```
Query [source/model] and show me:
1. Row count
2. Count of distinct values for [key columns]
3. Distribution of [categorical column]
4. Min, max, avg for [numeric columns]
5. Count and percentage of nulls for each column
6. Any obvious data quality issues
```

---

## The Workflow

If you remember only one thing from this workshop, make it this:

```
1. Define the task clearly        → one thing, not three
2. Give project context           → models, conventions, goal
3. Use MCP + Skills               → ground Claude in the project
4. Review the output              → every time, no exceptions
5. Test and validate              → run it, confirm it works
6. Iterate                        → small steps, visible progress
```

---

## Common Mistakes to Avoid

**"Fix this bug"** — Always separate diagnosis from fix. Two prompts, not one.

**"Make a complete data warehouse"** — Scope to one model at a time. Focused tasks produce better output.

**"Write me the SQL"** — Describe the business requirement instead. Claude writes better SQL when it understands WHY.

**Trusting output without validation** — Always run `dbt build` after every change. "It compiles" ≠ "it's correct."

**Skipping tests** — Generate tests alongside models. Build and test are one step, not two.

**Ignoring filler descriptions** — "The customer ID" teaches nobody anything. If the description doesn't add information beyond the column name, rewrite it.

---

## Notes for Attendees

- All data is synthetic — no external sources or credentials needed
- The `orders` mart contains an **intentional fanout bug** — joining payments without aggregating first causes duplicate rows. This is the debugging exercise in Lesson 4.
- The `customers` mart is **intentionally incomplete** — it lacks payment metrics (lifetime value, etc). You will extend it in Lesson 3.
- `workshop.duckdb` is git-ignored; each attendee generates their own local copy.

---

## Resources

- [dbt MCP Server Setup](https://docs.getdbt.com/docs/dbt-ai/setup-local-mcp)
- [dbt Agent Skills](https://github.com/dbt-labs/dbt-agent-skills)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Agent Skills Specification](https://agentskills.org)
