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

pip install dbt-core dbt-duckdb
npm install -g @anthropic-ai/claude-code
```

**Windows**

```powershell
# Install winget if you don't have it (comes with Windows 11; search "App Installer" in the Microsoft Store for Windows 10)

winget install Python.Python.3.11
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Microsoft.VisualStudioCode

pip install dbt-core dbt-duckdb
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

# 3. Install dbt with DuckDB adapter
pip install dbt-core dbt-duckdb

# 4. Verify
dbt --version

# 5. Run the project
dbt seed
dbt run
dbt test
```

Running `dbt seed` + `dbt run` + `dbt test` will create a local `dev.duckdb` file with all models materialized.

---

## Project Structure

```
odsc-demo/
├── seeds/
│   ├── raw_customers.csv      # 10 sample customers
│   └── raw_orders.csv         # 20 sample orders
├── models/
│   ├── staging/
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   └── schema.yml         # tests + documentation
│   └── marts/
│       ├── customers.sql      # customer summary with order metrics
│       └── schema.yml
├── dbt_project.yml
└── profiles.yml               # DuckDB local connection
```

Staging models are materialized as **views**. Mart models are materialized as **tables**.

---

## Workshop Lessons

| # | Topic |
|---|-------|
| 1 | Why generic AI prompting breaks down in real dbt projects |
| 2 | Connecting Claude to dbt with MCP and Agent Skills |
| 3 | Build models, tests, and documentation faster |
| 4 | Debug dbt issues with a context-aware workflow |

---

## Connecting Claude Code (dbt MCP)

Setup instructions for dbt MCP and dbt Agent Skills will be added here before the session.

---

## Notes for Attendees

- All data is synthetic — no external sources or credentials needed
- The `customers` mart model contains an intentional issue used in the debugging lesson — do not fix it in advance!
- `dev.duckdb` is git-ignored; each attendee generates their own local copy
