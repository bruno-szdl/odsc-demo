# ODSC East — Workshop Prerequisites
**Session:** Build, Test, and Debug dbt Faster with Claude
**Speaker:** Bruno Souza de Lima
**Format:** Workshop (1 hour, hands-on)

---

## Downloadable Prerequisites

Attendees should install the following **before** the session. Wi-Fi will not be required for setup if this is done in advance.

### macOS

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Python, Git, Node.js
brew install python git node

# VS Code
brew install --cask visual-studio-code

# dbt with DuckDB adapter
pip install dbt-core dbt-duckdb

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Clone the workshop repo
git clone <repo-url-tbd>
```

### Windows

```powershell
# winget comes with Windows 11; for Windows 10 search "App Installer" in the Microsoft Store

# Python, Git, Node.js, VS Code
winget install Python.Python.3.11
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Microsoft.VisualStudioCode

# dbt with DuckDB adapter
pip install dbt-core dbt-duckdb

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Clone the workshop repo
git clone <repo-url-tbd>
```

### Verify installation

```bash
python --version    # 3.11+
git --version
node --version
dbt --version
claude --version
```

---

## Approximate Total Download Size

| Item | Size |
|------|------|
| Python | ~30 MB |
| Git | ~50 MB |
| Node.js | ~35 MB |
| VS Code | ~90 MB |
| dbt-core + dbt-duckdb | ~80 MB |
| Claude Code CLI | ~15 MB |
| Workshop repo | < 5 MB |
| **Total** | **~305 MB** |

All tools are free and open source except Claude (see below).

---

## Paid Platforms

**Yes — Claude access is required.**

Claude Code is the primary AI tool used in this workshop. Attendees will need one of the following:

| Option | Cost | Notes |
|--------|------|-------|
| Claude.ai Pro | $20/month | Includes Claude Code access. Recommended. |
| Anthropic API key | Pay-per-use | ~$1–5 for a 1-hour session at typical usage. |

**Anthropic does not offer a fully free tier that includes Claude Code.** Attendees should sign up and add billing in advance at https://console.anthropic.com or subscribe at https://claude.ai.

> Note: A free claude.ai account may be used to follow along the conceptual portions, but the hands-on exercises require Claude Code CLI access.

---

## Non-Downloadable Prerequisites

These require an internet connection to set up, ideally before the session:

1. **GitHub account** — free, at https://github.com — to clone the workshop repo and follow along
2. **Anthropic account** — at https://claude.ai or https://console.anthropic.com — to authenticate Claude Code
3. **dbt MCP configuration** — a short setup step done inside VS Code using the workshop repo; instructions will be in the repo README
4. **dbt Agent Skills configuration** — similarly configured from the repo; instructions provided

> These configurations will be walked through at the start of the session. Attendees who complete them in advance will have more time for the hands-on exercises.

---

## Background Knowledge Expected

- Comfortable writing SQL
- Prior exposure to dbt concepts: models, schema YAML, tests
- Familiar with command-line basics and a code editor
- No prior experience with Claude, dbt MCP, or Agent Skills required

---

## Session Resources (to be finalized closer to the conference)

| Resource | Link |
|----------|------|
| Workshop GitHub repo | TBD |
| Setup instructions | TBD (will be in repo README) |
| Slide deck | TBD |

> This document will be updated as links are finalized. All hands-on materials will be available in the GitHub repository.
