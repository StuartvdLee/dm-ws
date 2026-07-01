# Dunder Mifflin Workshop — Student Repo

> This is the hands-on repo for the **Agentic AI Masterclass** workshop.
> You will build a series of AI agents around a fictional Dunder Mifflin
> package-manager scenario across eight parts.

## Quick start

```bash
python -m venv .venv
# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
cp .env.example .env   # fill in your Azure credentials
```

## Baseline branches

Each part has a known-good fallback you can switch to if you fall behind:

| Part | Branch |
|------|--------|
| 1 — Framing & first agent | `baselines/10-first-agent` |
| 2 — Context engineering | `baselines/10-30-context-map` |
| 3 — Specs, memory & personas | `baselines/11-spec` |
| 4 — Baseline & MCP fundamentals | `baselines/12-mcp-design` |
| 5 — Build the MCP server | `baselines/14-mcp-server` |
| 6 — Agent Framework & first MCP agent | `baselines/15-agent` |
| 7 — Native tools & A2A handoff | `baselines/16-a2a` |
| 8 — Human-in-the-loop | `baselines/17-hitl` |

Switch with: `git stash && git checkout <branch> && git stash pop`