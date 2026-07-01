<#
.SYNOPSIS
  Scaffolds all baseline branches for the dm-ws student workshop repo.
  Run once from inside the workshop/ submodule directory.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

function Commit($msg) {
  git -C $repo add -A
  git -C $repo commit -m $msg
}

# ─── helpers ────────────────────────────────────────────────────────────────
function Write-File($rel, $content) {
  $path = Join-Path $repo $rel
  $dir  = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
}

# ════════════════════════════════════════════════════════════════════════════
# MAIN BRANCH  — shared scaffolding every branch inherits
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout main

Write-File 'README.md' @'
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
'@

Write-File 'requirements.txt' @'
# Core AI SDK — Azure OpenAI compatible
openai>=1.40.0
azure-identity>=1.16.0

# MCP server SDK (Part 5+)
mcp>=1.0.0

# Utilities
python-dotenv>=1.0.0
'@

Write-File '.env.example' @'
AZURE_OPENAI_ENDPOINT=https://<your-resource>.openai.azure.com/
AZURE_OPENAI_KEY=<your-key>
AZURE_OPENAI_DEPLOYMENT=gpt-4o
'@

Write-File '.gitignore' @'
.venv/
__pycache__/
*.pyc
.env
*.egg-info/
dist/
.pytest_cache/
'@

Write-File 'data/packages.json' @'
[
  {
    "id": "PKG-1037",
    "orderId": "1037",
    "status": "in_transit",
    "route": "R-2",
    "condition": "OK",
    "fragile": true,
    "label": "DM-1037 frgile  rte R-2"
  },
  {
    "id": "PKG-1042",
    "orderId": "1042",
    "status": "delivered",
    "route": "R-1",
    "condition": "damaged",
    "fragile": false,
    "label": "DM-1042 rte R-1"
  },
  {
    "id": "PKG-1055",
    "orderId": "1055",
    "status": "pending",
    "route": "R-3",
    "condition": "OK",
    "fragile": false,
    "label": "DM-1055 rte R-3"
  },
  {
    "id": "PKG-1060",
    "orderId": "1060",
    "status": "exception",
    "route": "R-2",
    "condition": "missing label",
    "fragile": false,
    "label": ""
  }
]
'@

Write-File 'data/routes.json' @'
[
  { "id": "R-1", "driver": "Darryl Philbin",  "area": "North", "packages": ["PKG-1042"] },
  { "id": "R-2", "driver": "Roy Anderson",    "area": "East",  "packages": ["PKG-1037", "PKG-1060"] },
  { "id": "R-3", "driver": "Lonnie Collins",  "area": "West",  "packages": ["PKG-1055"] }
]
'@

Write-File 'data/policy.md' @'
# Dunder Mifflin Shipping Policy

## Package conditions

| Condition | Meaning | Action |
|-----------|---------|--------|
| `OK` | Package is undamaged and on schedule | No action needed |
| `damaged` | Physical damage observed | Flag for inspection; do not deliver without approval |
| `unclear` | Condition cannot be determined remotely | Schedule inspection |
| `missing label` | Label absent or unreadable | Hold; contact sender |
| `wrong address` | Label address does not match manifest | Hold; contact sender |
| `needs inspection` | Requires manual check before next step | Route to inspection bay |

## Fragile packages
- Must not be stacked.
- Route R-2 has confirmed fragile handling.

## Approval-required actions
- Changing a package status from `in_transit` to any exception state.
- Rerouting a package that is already `in_transit`.
- Any action on packages marked `damaged`.
'@

Commit "chore: shared scaffolding — data, requirements, gitignore"


# ════════════════════════════════════════════════════════════════════════════
# baselines/10-first-agent
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/10-first-agent

Write-File 'labs/10_first_agent.py' @'
"""Part 1 — First agent.

Answers questions about Dunder Mifflin orders by giving the model
the full package data as context. No tools, no retrieval — just
a raw context window.

Run:
    python labs/10_first_agent.py --ask "Where is order #1037?"
    python labs/10_first_agent.py --ask "Which packages are on route R-2?"
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from dotenv import load_dotenv
from openai import AzureOpenAI

load_dotenv()

# ── Load data ────────────────────────────────────────────────────────────────
_root = Path(__file__).parent.parent
PACKAGES = json.loads((_root / "data/packages.json").read_text())
ROUTES   = json.loads((_root / "data/routes.json").read_text())

# ── Azure OpenAI client ──────────────────────────────────────────────────────
client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_KEY"],
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
)
MODEL = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")

SYSTEM = f"""You are the Dunder Mifflin package manager assistant.
You help warehouse staff and managers look up package status, routes, and conditions.

Current package data:
{json.dumps(PACKAGES, indent=2)}

Current route data:
{json.dumps(ROUTES, indent=2)}

Answer questions based only on the data above. If something is not in the data, say so.
"""


def ask(question: str) -> str:
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": SYSTEM},
            {"role": "user",   "content": question},
        ],
    )
    return response.choices[0].message.content or ""


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Dunder Mifflin first agent")
    parser.add_argument("--ask", required=True, help="Question to ask the agent")
    args = parser.parse_args()
    print(ask(args.ask))
'@

Commit "feat(part1): first agent — raw context window over package data"


# ════════════════════════════════════════════════════════════════════════════
# baselines/10-30-context-map
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/10-30-context-map

Write-File 'docs/context-map.md' @'
# Context map — Dunder Mifflin package manager agent

> **Part 2 deliverable.** Classify every candidate fact the agent might use.
> Each item must be marked **include**, **retrieve on demand**, or **exclude**.

| # | Candidate fact | Classification | Reason |
|---|---------------|----------------|--------|
| 1 | Current package status (in_transit, delivered, exception …) | include | Needed in almost every answer |
| 2 | Package condition (OK, damaged, missing label …) | include | Safety-critical; always relevant |
| 3 | Active route and driver for a package | include | Core operational data |
| 4 | Full history of all past deliveries (all time) | retrieve on demand | Too large for every call; only needed for trend questions |
| 5 | Other packages on the same route | retrieve on demand | Only relevant when a route problem is suspected |
| 6 | Customer name and contact details | exclude | PII — agent must never surface this |
| 7 | Employee salary or HR records | exclude | Out of scope; safety and privacy |
| 8 | Real-time GPS coordinates of drivers | retrieve on demand | Only needed for live tracking questions |
| 9 | Fragile flag on package | include | Affects handling decisions |
| 10 | Shipping policy rules (conditions, approvals) | include | Agent must follow these rules |

## Open questions for Part 3 (memory)

- Should a user's display preferences (e.g. Stanley collapsing old deliveries) be remembered?
- Should the agent remember which order a user was just looking at within a session?
- Who should be allowed to mark a preference? (role-based)
'@

Commit "feat(part2): context map baseline"


# ════════════════════════════════════════════════════════════════════════════
# baselines/11-spec
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/11-spec

Write-File 'docs/spec.md' @'
# Package Manager Agent — Specification (baseline)

> **Part 3 baseline.** Refined spec with functional requirements, memory
> requirements, and bounded personas.

## Functional requirements

- **FR-PM-001 — Package lookup**: The system MUST return a package'\''s current
  status, route, and condition given a package or order identifier.
  *Acceptance*: a known package returns exactly one record; an unknown
  identifier returns a clear "not found", never a guess.
- **FR-PM-002 — Order status**: The system MUST report an order'\''s status
  (pending, in transit, delivered, exception).
  *Acceptance*: status matches the source record; ambiguous orders return a
  disambiguation prompt.
- **FR-PM-003 — Route awareness**: The system MUST identify which route a
  package is on and list other packages on that route when asked.
  *Acceptance*: only packages truly on the route are returned; none are
  invented.
- **FR-PM-004 — Label interpretation**: The system MUST parse a shipping label
  into structured fields (order, fragile flag, route).
  *Acceptance*: a valid label yields all three fields; a malformed label is
  rejected with a reason, not silently accepted.

## Memory requirements

- **MR-001 — User preference memory**: The system MAY remember a user'\''s
  display preferences across sessions. *For whom*: that user only.
  *For how long*: until the user changes or clears it.
- **MR-002 — Role-based behaviour**: The system MUST apply role-based response
  rules from the user'\''s role, not from stored personal data.
- **MR-003 — Working memory**: Within a conversation, the system MUST remember
  the order or route currently under discussion.

## Never store

- Real customer or employee PII.
- Credentials, tokens, or secrets.
- Anything a persona would use to hide safety- or compliance-critical information.

## Show for confirmation

- Before persisting a new long-term preference, the system MUST show the user
  what it will remember and ask for confirmation.

## Personas

| Persona | Preference | Behaviour change | Hard boundary |
|---------|------------|-----------------|---------------|
| **Stanley** | Minimise visual noise | Collapse statuses marked low-interest | MUST NOT hide safety-critical statuses |
| **Dwight** | Priority handling | Apply escalation policy on flagged orders | MUST NOT bypass approval rules |
| **Kevin** | Route trivia | Add "points of interest" annotation to route summaries | Informational only; MUST NOT change routing |
| **Warehouse staff** | Operational clarity | Concise, action-first language; no jokes | MUST NOT omit required warnings |

## Acceptance criteria

- **Correct use**: Remembered preference changes only presentation; user can inspect and clear it; nothing on the "never store" list is persisted.
- **Incorrect use (must fail review)**: Storing PII; persisting a preference without confirmation; letting a persona hide a safety-critical status.
'@

Commit "feat(part3): refined spec baseline"


# ════════════════════════════════════════════════════════════════════════════
# baselines/12-mcp-design
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/12-mcp-design

Write-File 'docs/mcp-design.md' @'
# MCP capability design — Dunder Mifflin package manager (baseline)

> **Part 4 baseline.** Maps the package manager spec onto MCP primitives
> (resources, prompts, tools). Use this as the blueprint for Part 5.

## Capability mapping

| Capability | MCP concept | Description | Inputs | Output | Read-only / approval |
|------------|-------------|-------------|--------|--------|----------------------|
| Package data | resource | Current packages with status, route, condition | — | — | read-only |
| Route data | resource | Routes and the packages on each | — | — | read-only |
| Data schema | resource | Shape of package, order, and route records | — | — | read-only |
| Policy document | resource | Shipping and condition rules the agent must respect | — | — | read-only |
| Investigate a delayed package | prompt | Reusable workflow: gather status, route, and history | — | — | — |
| Look up order status | tool | Return status, route, and condition for an order | `orderId: string` | `{ status, route, condition }` | read-only |
| Look up route | tool | Return route details and all packages on it | `routeId: string` | `{ driver, area, packages[] }` | read-only |
| Parse label | tool | Turn a shipping label into structured fields | `label: string` | `{ orderId, fragile, route }` | read-only |
| Update package status | tool | Change a package'\''s status | `packageId: string`, `status: enum` | `{ ok: boolean }` | **approval-required** |

## MCP design checklist

- [x] ≥5 capabilities mapped to resource / prompt / tool.
- [x] Read-oriented context mapped to **resources** (package data, route data, schema, policy).
- [x] ≥1 reusable workflow mapped to a **prompt** (investigate-delayed-package).
- [x] ≥3 tools with named inputs and expected output.
- [x] Every operation marked **read-only** or **approval-required**.
- [x] State-changing operations marked **approval-required** for the HITL segment (Part 8).

## Open questions for the Part 5 build

- Transport: stdio (local) or HTTP (remote)?
- Where is the package data hosted — file, database, or live API?
- Which tools need input validation for unknown IDs?
'@

Commit "feat(part4): MCP design baseline"


# ════════════════════════════════════════════════════════════════════════════
# baselines/14-mcp-server
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/14-mcp-server

Write-File 'packagemcp/__init__.py' '# Dunder Mifflin Package Manager MCP server.'

Write-File 'packagemcp/_data.py' @'
"""Shared in-memory data store loaded from data/ at import time."""
from __future__ import annotations
import json
from pathlib import Path

_root = Path(__file__).parent.parent
PACKAGES: list[dict] = json.loads((_root / "data/packages.json").read_text())
ROUTES:   list[dict] = json.loads((_root / "data/routes.json").read_text())
POLICY:   str        = (_root / "data/policy.md").read_text()


def find_package_by_order(order_id: str) -> dict | None:
    return next((p for p in PACKAGES if p["orderId"] == order_id), None)


def find_route(route_id: str) -> dict | None:
    return next((r for r in ROUTES if r["id"] == route_id), None)
'@

Write-File 'packagemcp/server.py' @'
"""Dunder Mifflin Package Manager MCP server (Part 5).

Exposes:
  Resources : package-data, route-data, data-schema, package-status-policy
  Prompts   : investigate-delayed-package
  Tools     : lookup_order_status, lookup_route, parse_label, update_package_status
"""
from __future__ import annotations

import re
from mcp.server.fastmcp import FastMCP

from ._data import PACKAGES, ROUTES, POLICY, find_package_by_order, find_route

mcp = FastMCP("dm-package-manager")

# ── Resources ────────────────────────────────────────────────────────────────

@mcp.resource("dm://packages")
def package_data() -> str:
    """All current packages with status, route, and condition."""
    import json
    return json.dumps(PACKAGES, indent=2)


@mcp.resource("dm://routes")
def route_data() -> str:
    """All routes with driver, area, and package list."""
    import json
    return json.dumps(ROUTES, indent=2)


@mcp.resource("dm://schema")
def data_schema() -> str:
    """Shape of the package, route, and order records."""
    return """\
Package record fields:
  id         string   Unique package identifier (e.g. PKG-1037)
  orderId    string   Customer order number
  status     enum     pending | in_transit | delivered | exception
  route      string   Route identifier (e.g. R-2)
  condition  enum     OK | damaged | unclear | missing label | wrong address | needs inspection
  fragile    boolean  True if the package requires careful handling
  label      string   Raw shipping label text

Route record fields:
  id         string   Route identifier
  driver     string   Driver name
  area       string   Geographic area
  packages   list     Package IDs currently on this route
"""


@mcp.resource("dm://policy")
def package_status_policy() -> str:
    """Shipping and condition rules the agent must respect."""
    return POLICY


# ── Prompts ──────────────────────────────────────────────────────────────────

@mcp.prompt()
def investigate_delayed_package(orderId: str) -> str:
    """Reusable workflow for investigating a delayed or problematic package."""
    return f"""\
Investigate the package for order {orderId}. Follow these steps:

1. Call lookup_order_status("{orderId}") to get the current status, route, and condition.
2. If a route is returned, call lookup_route(<routeId>) to see all packages on that route.
3. Check the condition against the policy (dm://policy).
4. Summarise findings and propose one concrete next step for Darryl.

Ground every claim in a tool result. If you have not looked something up, say so.
"""


# ── Tools ────────────────────────────────────────────────────────────────────

@mcp.tool()
def lookup_order_status(orderId: str) -> dict:
    """Return status, route, and condition for an order. Read-only.

    Args:
        orderId: The customer order number (e.g. "1037").
    """
    pkg = find_package_by_order(orderId)
    if not pkg:
        return {"error": "order not found", "orderId": orderId}
    return {
        "orderId":   pkg["orderId"],
        "packageId": pkg["id"],
        "status":    pkg["status"],
        "route":     pkg["route"],
        "condition": pkg["condition"],
        "fragile":   pkg["fragile"],
    }


@mcp.tool()
def lookup_route(routeId: str) -> dict:
    """Return route details and all packages currently on it. Read-only.

    Args:
        routeId: The route identifier (e.g. "R-2").
    """
    route = find_route(routeId)
    if not route:
        return {"error": "route not found", "routeId": routeId}
    packages_on_route = [p for p in PACKAGES if p["route"] == routeId]
    return {
        "routeId":  route["id"],
        "driver":   route["driver"],
        "area":     route["area"],
        "packages": packages_on_route,
    }


@mcp.tool()
def parse_label(label: str) -> dict:
    """Parse a raw shipping label into structured fields. Read-only.

    Args:
        label: Raw label text, e.g. "DM-1037 frgile  rte R-2".
    """
    if not label or not label.strip():
        return {"error": "empty label", "rawLabel": label}

    text = label.strip()

    # Order ID: DM-NNNN
    order_match = re.search(r"DM-(\d+)", text, re.IGNORECASE)
    order_id = order_match.group(1) if order_match else None

    # Fragile: "fragile" or common misspellings
    fragile = bool(re.search(r"fr[ai]g[il]+e?", text, re.IGNORECASE))

    # Route: rte or route followed by ID
    route_match = re.search(r"r(?:ou)?te?\s+([\w-]+)", text, re.IGNORECASE)
    route = route_match.group(1).upper() if route_match else None

    if not order_id:
        return {
            "error":    "could not parse order ID from label",
            "rawLabel": label,
        }

    return {
        "orderId":  order_id,
        "fragile":  fragile,
        "route":    route,
        "rawLabel": label,
    }


@mcp.tool()
def update_package_status(packageId: str, status: str) -> dict:
    """Change a package'\''s status. APPROVAL-REQUIRED.

    This is a write operation. The agent MUST obtain explicit human approval
    before calling this tool. Valid statuses: pending, in_transit, delivered,
    exception.

    Args:
        packageId: The package identifier (e.g. "PKG-1037").
        status:    New status value.
    """
    valid = {"pending", "in_transit", "delivered", "exception"}
    if status not in valid:
        return {"ok": False, "error": f"invalid status '{status}'; must be one of {sorted(valid)}"}

    pkg = next((p for p in PACKAGES if p["id"] == packageId), None)
    if not pkg:
        return {"ok": False, "error": f"package '{packageId}' not found"}

    old_status = pkg["status"]
    pkg["status"] = status
    return {"ok": True, "packageId": packageId, "oldStatus": old_status, "newStatus": status}
'@

Write-File 'packagemcp/__main__.py' @'
"""CLI wrapper for the Package Manager MCP server (Part 5).

Usage:
    python -m packagemcp                           # run as MCP stdio server
    python -m packagemcp --list                    # list all capabilities
    python -m packagemcp --inspect                 # detailed capability listing
    python -m packagemcp --call <tool> --input '{}'
    python -m packagemcp --show-prompt <name>
    python -m packagemcp --show-resource <name>
"""
from __future__ import annotations

import argparse
import json
import sys


def _server():
    from .server import mcp
    mcp.run(transport="stdio")


def _list_capabilities():
    from .server import mcp
    print("=== Tools ===")
    for t in mcp.list_tools():
        print(f"  {t.name} — {(t.description or '').splitlines()[0]}")
    print("\n=== Prompts ===")
    for p in mcp.list_prompts():
        print(f"  {p.name} — {(p.description or '').splitlines()[0]}")
    print("\n=== Resources ===")
    for r in mcp.list_resources():
        print(f"  {r.uri} — {(r.description or '').splitlines()[0]}")


def _inspect():
    from .server import mcp
    import json as _json
    print("=== Tools ===")
    for t in mcp.list_tools():
        print(f"\n  {t.name}")
        print(f"  Description : {t.description}")
        if t.inputSchema:
            print(f"  Input schema: {_json.dumps(t.inputSchema, indent=4)}")
    print("\n=== Prompts ===")
    for p in mcp.list_prompts():
        print(f"\n  {p.name}")
        print(f"  Description : {p.description}")
        if p.arguments:
            for a in p.arguments:
                print(f"  Arg         : {a.name} ({'required' if a.required else 'optional'})")
    print("\n=== Resources ===")
    for r in mcp.list_resources():
        print(f"\n  {r.uri}")
        print(f"  Description : {r.description}")


def _call_tool(name: str, raw_input: str):
    from .server import mcp
    import asyncio, json as _json
    kwargs = _json.loads(raw_input) if raw_input else {}
    # FastMCP exposes tools as callables on mcp._tool_manager
    tools = {t.name: t for t in mcp.list_tools()}
    if name not in tools:
        print(f"Unknown tool: {name}", file=sys.stderr)
        sys.exit(1)
    result = asyncio.run(mcp.call_tool(name, kwargs))
    print(_json.dumps(result, indent=2, default=str))


def _show_prompt(name: str, args: dict | None = None):
    from .server import mcp
    import asyncio, json as _json
    result = asyncio.run(mcp.get_prompt(name, args or {}))
    for msg in result.messages:
        print(msg.content.text if hasattr(msg.content, "text") else str(msg.content))


def _show_resource(uri: str):
    from .server import mcp
    import asyncio
    result = asyncio.run(mcp.read_resource(uri))
    for content in result:
        print(content.text if hasattr(content, "text") else str(content))


def main():
    parser = argparse.ArgumentParser(description="Package Manager MCP server CLI")
    parser.add_argument("--list",          action="store_true", help="List all capabilities")
    parser.add_argument("--inspect",       action="store_true", help="Detailed capability listing")
    parser.add_argument("--call",          metavar="TOOL",      help="Call a tool by name")
    parser.add_argument("--input",         default="{}",        help="JSON input for --call")
    parser.add_argument("--show-prompt",   metavar="NAME",      help="Show a prompt by name")
    parser.add_argument("--prompt-args",   default="{}",        help="JSON args for --show-prompt")
    parser.add_argument("--show-resource", metavar="URI",       help="Show a resource by URI")
    args = parser.parse_args()

    if args.list:
        _list_capabilities()
    elif args.inspect:
        _inspect()
    elif args.call:
        _call_tool(args.call, args.input)
    elif args.show_prompt:
        _show_prompt(args.show_prompt, json.loads(args.prompt_args))
    elif args.show_resource:
        _show_resource(args.show_resource)
    else:
        _server()


import json
if __name__ == "__main__":
    main()
'@

Commit "feat(part5): packagemcp — tools, prompt, resources, CLI"


# ════════════════════════════════════════════════════════════════════════════
# baselines/15-agent-start  (stub — student fills in the agent)
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/15-agent-start

Write-File 'packageagent/__init__.py' '# Dunder Mifflin package manager agent.'

Write-File 'packageagent/_mcp_client.py' @'
"""Thin async helper that spawns the MCP server as a subprocess and calls tools."""
from __future__ import annotations

import json
import asyncio
import subprocess
import sys
from pathlib import Path


async def call_tool(tool_name: str, arguments: dict) -> dict:
    """Spawn the MCP server, call one tool, return the result dict."""
    proc = await asyncio.create_subprocess_exec(
        sys.executable, "-m", "packagemcp", "--call", tool_name,
        "--input", json.dumps(arguments),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        cwd=Path(__file__).parent.parent,
    )
    stdout, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"MCP call failed: {stderr.decode()}")
    return json.loads(stdout.decode())
'@

Write-File 'packageagent/agent.py' @'
"""Part 6 — RegionalManagerAgent (student starter).

TODO: Fill in the three sections marked TODO below.
"""
from __future__ import annotations

import json
import os
from openai import AzureOpenAI
from dotenv import load_dotenv

load_dotenv()

client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_KEY"],
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
)
MODEL = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")

# TODO 1: Write explicit role instructions for the agent.
# Use docs/spec.md (role, allowed actions, boundaries, grounding rule, escalation).
SYSTEM_INSTRUCTIONS = """\
TODO: Give this agent an explicit role.
- Who does it serve?
- What is it allowed to do?
- What must it never do?
- When must it escalate or ask for clarification?
"""

# TODO 2: Define the tools the agent can call (MCP capabilities).
# These map to the tools in packagemcp/server.py.
TOOLS: list[dict] = [
    # TODO: Add at least one tool definition here.
    # Example shape:
    # {
    #   "type": "function",
    #   "function": {
    #     "name": "lookup_order_status",
    #     "description": "Return status, route, and condition for an order.",
    #     "parameters": {
    #       "type": "object",
    #       "properties": {"orderId": {"type": "string"}},
    #       "required": ["orderId"],
    #     },
    #   },
    # },
]


async def _execute_tool_call(name: str, arguments: dict) -> str:
    from ._mcp_client import call_tool
    result = await call_tool(name, arguments)
    return json.dumps(result)


async def investigate_order(order_id: str, show_steps: bool = False) -> str:
    """TODO 3: Implement the agentic loop.

    Steps:
    1. Send the user message to the model with TOOLS.
    2. If the model requests a tool call, execute it via _execute_tool_call.
    3. Append the tool result and loop until the model returns a final answer.
    4. Return the final answer.
    """
    # TODO: implement the agentic loop here.
    return "TODO: implement the agentic loop."
'@

Write-File 'packageagent/__main__.py' @'
"""CLI for the package manager agent (Part 6+).

Usage:
    python -m packageagent --check
    python -m packageagent --show
    python -m packageagent --order 1037
    python -m packageagent --order 1037 --show-steps
"""
from __future__ import annotations

import argparse
import asyncio
import sys


def main():
    parser = argparse.ArgumentParser(description="Package manager agent CLI")
    parser.add_argument("--check",       action="store_true", help="Verify MCP server is reachable")
    parser.add_argument("--show",        action="store_true", help="Show agent name, instructions, tools")
    parser.add_argument("--order",       metavar="ID",        help="Investigate an order")
    parser.add_argument("--show-steps",  action="store_true", help="Print each tool call made")
    parser.add_argument("--explain",     action="store_true", help="Validate grounding after --order")
    args = parser.parse_args()

    if args.check:
        import asyncio as _a
        from ._mcp_client import call_tool
        try:
            result = _a.run(call_tool("lookup_order_status", {"orderId": "1037"}))
            print("MCP server OK:", result)
        except Exception as exc:
            print(f"MCP server unreachable: {exc}", file=sys.stderr)
            sys.exit(1)

    elif args.show:
        from .agent import SYSTEM_INSTRUCTIONS, TOOLS, MODEL
        print(f"Model      : {MODEL}")
        print(f"Tools      : {[t['function']['name'] for t in TOOLS] if TOOLS else '(none defined)'}")
        print(f"Instructions:\n{SYSTEM_INSTRUCTIONS}")

    elif args.order:
        from .agent import investigate_order
        result = asyncio.run(investigate_order(args.order, show_steps=args.show_steps))
        print(result)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
'@

Commit "feat(part6-start): packageagent stub — student fills in role + agentic loop"


# ════════════════════════════════════════════════════════════════════════════
# baselines/15-agent  (complete implementation)
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/15-agent

Write-File 'packageagent/agent.py' @'
"""Part 6 — RegionalManagerAgent (complete baseline).

Investigates an order by calling MCP tools and produces a grounded
next-step proposal for Darryl.
"""
from __future__ import annotations

import json
import os
from openai import AzureOpenAI
from dotenv import load_dotenv

load_dotenv()

client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_KEY"],
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
)
MODEL = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")

SYSTEM_INSTRUCTIONS = """\
You are the RegionalManagerAgent for Dunder Mifflin's warehouse.
You help Darryl, the warehouse lead, decide the next operational step for a package or order.

Allowed actions:
- Look up package, order, and route details using the provided tools.
- Propose one clear next step based on what the tools return.

Boundaries:
- Never claim you physically moved, shipped, or rerouted anything.
- Never act on real systems. Only propose.

Grounding rule:
- Base every factual claim on a tool result.
- If you have not looked something up, say so rather than guessing.

Escalation:
- If an order is missing a route or condition is unclear, flag it for inspection.
- If the condition requires approval (damaged, exception), state that approval is required.
"""

TOOLS: list[dict] = [
    {
        "type": "function",
        "function": {
            "name": "lookup_order_status",
            "description": "Return status, route, and condition for an order. Read-only.",
            "parameters": {
                "type": "object",
                "properties": {"orderId": {"type": "string", "description": "Customer order number"}},
                "required": ["orderId"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "lookup_route",
            "description": "Return route details and all packages on the route. Read-only.",
            "parameters": {
                "type": "object",
                "properties": {"routeId": {"type": "string", "description": "Route identifier e.g. R-2"}},
                "required": ["routeId"],
            },
        },
    },
]


async def _execute_tool_call(name: str, arguments: dict, show_steps: bool) -> str:
    from ._mcp_client import call_tool
    if show_steps:
        print(f"  [tool call] {name}({json.dumps(arguments)})")
    result = await call_tool(name, arguments)
    if show_steps:
        print(f"  [tool result] {json.dumps(result)}")
    return json.dumps(result)


async def investigate_order(order_id: str, show_steps: bool = False) -> str:
    """Run the agentic loop to investigate an order and propose a next step."""
    messages: list[dict] = [
        {"role": "system", "content": SYSTEM_INSTRUCTIONS},
        {"role": "user",   "content": f"Investigate order {order_id} and propose the next operational step."},
    ]

    while True:
        response = client.chat.completions.create(
            model=MODEL,
            messages=messages,
            tools=TOOLS,
            tool_choice="auto",
        )
        msg = response.choices[0].message

        if msg.tool_calls:
            messages.append(msg)
            for tc in msg.tool_calls:
                args = json.loads(tc.function.arguments)
                result = await _execute_tool_call(tc.function.name, args, show_steps)
                messages.append({
                    "role":         "tool",
                    "tool_call_id": tc.id,
                    "content":      result,
                })
        else:
            return msg.content or ""
'@

Commit "feat(part6): RegionalManagerAgent — complete agentic loop"


# ════════════════════════════════════════════════════════════════════════════
# baselines/16-a2a-start  (native tool + PackageLabelParser stub)
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/16-a2a-start

Write-File 'packageagent/tools.py' @'
"""Part 7 — Native (in-process) function tools.

Native tools run in-process and are NOT served via MCP.
Use them for simple, synchronous operations that do not need to be
shared across multiple agents or clients.
"""
from __future__ import annotations

import re


def parse_label(label: str) -> dict:
    """TODO: Implement native label parser.

    Parse a raw shipping label into structured fields.
    - Input : label (str) — e.g. "DM-1037 frgile  rte R-2"
    - Output: { orderId, fragile, route } on success
             { error, rawLabel } on failure

    Requirements (from tool-contract checklist):
    - Typed inputs and outputs.
    - Invalid / empty label returns a clear error, never a guess.
    - Read-only; does not modify any data.
    """
    # TODO: implement this function.
    return {"error": "not implemented", "rawLabel": label}
'@

Write-File 'packageagent/label_parser_agent.py' @'
"""Part 7 — PackageLabelParser specialist agent (stub).

TODO: Implement the PackageLabelParser agent.

Handoff contract (from docs/handoff-contract.md):
  Caller       : RegionalManagerAgent
  Callee       : PackageLabelParser
  Task         : Parse a messy shipping label into structured fields.
  Input data   : rawLabel: string
  Returned     : { orderId, fragile, route, confidence } or { error, rawLabel }
  Failure      : returns error dict — never guesses, never writes to any system.
  Boundary     : parses text only; does not decide priorities, reroute, or act.
"""
from __future__ import annotations


async def parse(raw_label: str) -> dict:
    """TODO: implement the label parsing agent."""
    return {"error": "not implemented", "rawLabel": raw_label}
'@

# Update agent.py to wire in the native tool stub
Write-File 'packageagent/agent.py' @'
"""Part 7 — RegionalManagerAgent with native tool + A2A handoff (start baseline).

The native parse_label tool and PackageLabelParser handoff are stubbed.
TODO: implement packageagent/tools.py and packageagent/label_parser_agent.py.
"""
from __future__ import annotations

import json
import os
from openai import AzureOpenAI
from dotenv import load_dotenv

load_dotenv()

client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_KEY"],
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
)
MODEL = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")

SYSTEM_INSTRUCTIONS = """\
You are the RegionalManagerAgent for Dunder Mifflin'\''s warehouse.
You help Darryl decide the next operational step for a package or order.
Allowed: look up orders and routes via MCP tools; parse labels via the native parse_label tool.
Boundaries: never claim you acted on a system; only propose.
Grounding: base every claim on a tool result.
Escalation: delegate complex label parsing to PackageLabelParser.
"""

TOOLS: list[dict] = [
    {
        "type": "function",
        "function": {
            "name": "lookup_order_status",
            "description": "Return status, route, and condition for an order (MCP). Read-only.",
            "parameters": {
                "type": "object",
                "properties": {"orderId": {"type": "string"}},
                "required": ["orderId"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "lookup_route",
            "description": "Return route details and packages on a route (MCP). Read-only.",
            "parameters": {
                "type": "object",
                "properties": {"routeId": {"type": "string"}},
                "required": ["routeId"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "parse_label",
            "description": "Parse a raw shipping label into structured fields (native tool). Read-only.",
            "parameters": {
                "type": "object",
                "properties": {"label": {"type": "string", "description": "Raw label text"}},
                "required": ["label"],
            },
        },
    },
]


async def _dispatch(name: str, arguments: dict, show_steps: bool) -> str:
    from ._mcp_client import call_tool
    from .tools import parse_label
    from .label_parser_agent import parse as label_parser_agent_parse

    if show_steps:
        print(f"  [{name}] {json.dumps(arguments)}")

    if name == "parse_label":
        result = parse_label(arguments.get("label", ""))  # native
    elif name in {"lookup_order_status", "lookup_route"}:
        result = await call_tool(name, arguments)         # MCP
    else:
        result = {"error": f"unknown tool: {name}"}

    if show_steps:
        print(f"  → {json.dumps(result)}")
    return json.dumps(result)


async def investigate_order(order_id: str, show_steps: bool = False) -> str:
    messages: list[dict] = [
        {"role": "system", "content": SYSTEM_INSTRUCTIONS},
        {"role": "user",   "content": f"Investigate order {order_id} and propose the next step."},
    ]
    while True:
        response = client.chat.completions.create(
            model=MODEL, messages=messages, tools=TOOLS, tool_choice="auto",
        )
        msg = response.choices[0].message
        if msg.tool_calls:
            messages.append(msg)
            for tc in msg.tool_calls:
                args = json.loads(tc.function.arguments)
                result = await _dispatch(tc.function.name, args, show_steps)
                messages.append({"role": "tool", "tool_call_id": tc.id, "content": result})
        else:
            return msg.content or ""


async def handoff_label(raw_label: str, show_handoff: bool = False) -> dict:
    """Delegate label parsing to PackageLabelParser (A2A handoff)."""
    from .label_parser_agent import parse
    if show_handoff:
        print(f"  [handoff] RegionalManagerAgent → PackageLabelParser")
        print(f"  [input]   rawLabel={raw_label!r}")
    result = await parse(raw_label)
    if show_handoff:
        print(f"  [result]  {json.dumps(result)}")
    return result
'@

# Update __main__.py for part 7 commands
Write-File 'packageagent/__main__.py' @'
"""CLI for the package manager agent (Part 7).

Usage:
    python -m packageagent --check
    python -m packageagent --show
    python -m packageagent --show-tools
    python -m packageagent --compare-tools
    python -m packageagent --order 1037
    python -m packageagent --order 1037 --show-steps
    python -m packageagent --handoff --label "DM-1037 frgile  rte R-2"
    python -m packageagent --handoff --label "???" --show-handoff
"""
from __future__ import annotations
import argparse, asyncio, sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check",        action="store_true")
    parser.add_argument("--show",         action="store_true")
    parser.add_argument("--show-tools",   action="store_true")
    parser.add_argument("--compare-tools",action="store_true")
    parser.add_argument("--order",        metavar="ID")
    parser.add_argument("--show-steps",   action="store_true")
    parser.add_argument("--handoff",      action="store_true")
    parser.add_argument("--label",        default="")
    parser.add_argument("--show-handoff", action="store_true")
    args = parser.parse_args()

    if args.check:
        from ._mcp_client import call_tool
        try:
            r = asyncio.run(call_tool("lookup_order_status", {"orderId": "1037"}))
            print("MCP OK:", r)
        except Exception as e:
            print("MCP unreachable:", e, file=sys.stderr); sys.exit(1)

    elif args.show:
        from .agent import SYSTEM_INSTRUCTIONS, TOOLS, MODEL
        print(f"Model: {MODEL}")
        print(f"Tools: {[t['function']['name'] for t in TOOLS]}")
        print(f"Instructions:\n{SYSTEM_INSTRUCTIONS}")

    elif args.show_tools:
        from .agent import TOOLS
        from ._mcp_client import call_tool
        print("Native tools : parse_label")
        print("MCP tools    :", [t["function"]["name"] for t in TOOLS if t["function"]["name"] != "parse_label"])

    elif args.compare_tools:
        print("Native (parse_label)  : runs in-process, no network, synchronous, not shareable")
        print("MCP (lookup_*)        : runs in subprocess/server, network-capable, shareable across agents")

    elif args.order:
        from .agent import investigate_order
        print(asyncio.run(investigate_order(args.order, show_steps=args.show_steps)))

    elif args.handoff:
        from .agent import handoff_label
        import json
        r = asyncio.run(handoff_label(args.label, show_handoff=args.show_handoff))
        print(json.dumps(r, indent=2))

    else:
        parser.print_help()

if __name__ == "__main__":
    main()
'@

Write-File 'docs/handoff-contract.md' @'
# A2A Handoff Contract — RegionalManagerAgent → PackageLabelParser

> **Part 7 deliverable.** Fill this in before you implement the handoff.
> A delegation you cannot describe this precisely is one you cannot validate.

| Field | Value |
|-------|-------|
| **Caller** | `RegionalManagerAgent` |
| **Callee** | `PackageLabelParser` |
| **Task** | Parse a messy shipping label into structured fields |
| **Input data** | `rawLabel: string` — e.g. `"DM-1037 frgile  rte R-2"` |
| **Returned artifact** | `{ orderId: string, fragile: boolean, route: string, confidence: float }` |
| **Failure behaviour** | If label cannot be parsed: `{ error: "unparseable", rawLabel }` — never guess, never write |
| **Boundary** | `PackageLabelParser` parses text only; does not decide priorities, reroute, or act on any system |
'@

Commit "feat(part7-start): native parse_label stub + PackageLabelParser stub + handoff contract"


# ════════════════════════════════════════════════════════════════════════════
# baselines/16-a2a  (complete)
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/16-a2a

Write-File 'packageagent/tools.py' @'
"""Part 7 — Native (in-process) function tools (complete baseline)."""
from __future__ import annotations
import re


def parse_label(label: str) -> dict:
    """Parse a raw shipping label into structured fields. Read-only.

    Returns { orderId, fragile, route, confidence } or { error, rawLabel }.
    """
    if not label or not label.strip():
        return {"error": "empty label", "rawLabel": label}

    text = label.strip()
    order_match = re.search(r"DM-(\d+)", text, re.IGNORECASE)
    fragile     = bool(re.search(r"fr[ai]g[il]+e?", text, re.IGNORECASE))
    route_match = re.search(r"r(?:ou)?te?\s+([\w-]+)", text, re.IGNORECASE)

    if not order_match:
        return {"error": "could not parse order ID", "rawLabel": label}

    confidence = 1.0
    if not route_match:
        confidence -= 0.2

    return {
        "orderId":    order_match.group(1),
        "fragile":    fragile,
        "route":      route_match.group(1).upper() if route_match else None,
        "confidence": round(confidence, 2),
        "rawLabel":   label,
    }
'@

Write-File 'packageagent/label_parser_agent.py' @'
"""Part 7 — PackageLabelParser specialist agent (complete baseline).

Uses the native parse_label tool. In a more complex setup this could
be a full LLM-backed agent; here it is a thin wrapper that enforces
the handoff contract.
"""
from __future__ import annotations
from .tools import parse_label


async def parse(raw_label: str) -> dict:
    """Parse a label, enforcing the handoff contract boundary.

    Returns { orderId, fragile, route, confidence } or { error, rawLabel }.
    Does NOT decide priorities, reroute, or act on any system.
    """
    return parse_label(raw_label)
'@

Commit "feat(part7): complete native parse_label + PackageLabelParser"


# ════════════════════════════════════════════════════════════════════════════
# baselines/17-hitl-start  (condition checker stub)
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/17-hitl-start

Write-File 'packageagent/condition_checker.py' @'
"""Part 8 — PackageConditionChecker (stub).

TODO: Implement the condition checker.

The checker evaluates a package'\''s condition from structured data
(and optionally a text description / image description) and returns
one of the allowed condition values plus a recommended action.

Allowed condition values: OK | damaged | unclear | missing label | wrong address | needs inspection

Requirements:
- Must return a structured result, never free text only.
- Must include a recommended_action field.
- If condition cannot be determined, return "unclear" + "needs inspection" — never guess.
- Any state-changing action (e.g. updating package status) requires explicit human approval.
"""
from __future__ import annotations

ALLOWED_CONDITIONS = {
    "OK", "damaged", "unclear", "missing label", "wrong address", "needs inspection"
}


async def check_condition(order_id: str, description: str | None = None) -> dict:
    """TODO: implement the condition checker.

    Args:
        order_id    : The order to inspect.
        description : Optional free-text description or image description.

    Returns:
        {
          "orderId":            str,
          "condition":          one of ALLOWED_CONDITIONS,
          "recommended_action": str,
          "requires_approval":  bool,
          "reasoning":          str,
        }
    """
    return {
        "orderId":            order_id,
        "condition":          "unclear",
        "recommended_action": "TODO: implement",
        "requires_approval":  True,
        "reasoning":          "TODO: not implemented",
    }
'@

# Update __main__.py to add Part 8 commands
Write-File 'packageagent/__main__.py' @'
"""CLI for the package manager agent (Part 8).

Usage:
    python -m packageagent --check
    python -m packageagent --order 1037
    python -m packageagent --order 1037 --show-steps
    python -m packageagent --handoff --label "DM-1037 frgile  rte R-2"
    python -m packageagent --check-condition --order 1037
    python -m packageagent --check-condition --order 1037 --propose-action
"""
from __future__ import annotations
import argparse, asyncio, json, sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check",           action="store_true")
    parser.add_argument("--show",            action="store_true")
    parser.add_argument("--show-tools",      action="store_true")
    parser.add_argument("--compare-tools",   action="store_true")
    parser.add_argument("--order",           metavar="ID")
    parser.add_argument("--show-steps",      action="store_true")
    parser.add_argument("--handoff",         action="store_true")
    parser.add_argument("--label",           default="")
    parser.add_argument("--show-handoff",    action="store_true")
    parser.add_argument("--check-condition", action="store_true")
    parser.add_argument("--propose-action",  action="store_true")
    args = parser.parse_args()

    if args.check:
        from ._mcp_client import call_tool
        try:
            r = asyncio.run(call_tool("lookup_order_status", {"orderId": "1037"}))
            print("MCP OK:", r)
        except Exception as e:
            print("MCP unreachable:", e, file=sys.stderr); sys.exit(1)

    elif args.order:
        from .agent import investigate_order
        print(asyncio.run(investigate_order(args.order, show_steps=args.show_steps)))

    elif args.handoff:
        from .agent import handoff_label
        print(json.dumps(asyncio.run(handoff_label(args.label, show_handoff=args.show_handoff)), indent=2))

    elif args.check_condition:
        if not args.order:
            print("--check-condition requires --order", file=sys.stderr); sys.exit(1)
        from .condition_checker import check_condition
        result = asyncio.run(check_condition(args.order))
        print(json.dumps(result, indent=2))
        if args.propose_action and result.get("requires_approval"):
            print("\n⚠  This action requires human approval before proceeding.")
            answer = input(f"Approve '{result['recommended_action']}'? [y/N] ")
            if answer.strip().lower() == "y":
                print("✓  Approved — action would be executed here.")
            else:
                print("✗  Declined — no changes made.")

    else:
        parser.print_help()

if __name__ == "__main__":
    main()
'@

Commit "feat(part8-start): PackageConditionChecker stub + --check-condition CLI"


# ════════════════════════════════════════════════════════════════════════════
# baselines/17-hitl  (complete)
# ════════════════════════════════════════════════════════════════════════════
git -C $repo checkout -b baselines/17-hitl

Write-File 'packageagent/condition_checker.py' @'
"""Part 8 — PackageConditionChecker (complete baseline).

Evaluates a package'\''s condition using the MCP lookup tool and an LLM
assessment. Flags any state-changing action as approval-required.
"""
from __future__ import annotations

import json
import os
from openai import AzureOpenAI
from dotenv import load_dotenv

load_dotenv()

client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_KEY"],
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
)
MODEL = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")

ALLOWED_CONDITIONS = {
    "OK", "damaged", "unclear", "missing label", "wrong address", "needs inspection"
}

_SYSTEM = """\
You are PackageConditionChecker for Dunder Mifflin warehouse.
Given package data and an optional description, return a JSON object:
{
  "condition":          one of: OK | damaged | unclear | missing label | wrong address | needs inspection,
  "recommended_action": one sentence describing the next step,
  "requires_approval":  true if the action changes any system state; false for read-only observations,
  "reasoning":          one sentence explaining the condition assessment
}
Base the assessment only on the data provided. If condition is uncertain, use "unclear".
"""


async def check_condition(order_id: str, description: str | None = None) -> dict:
    """Assess a package'\''s condition and return a structured result."""
    from ._mcp_client import call_tool

    pkg_data = await call_tool("lookup_order_status", {"orderId": order_id})
    if "error" in pkg_data:
        return {
            "orderId":            order_id,
            "condition":          "unclear",
            "recommended_action": "Verify order ID and retry.",
            "requires_approval":  False,
            "reasoning":          pkg_data["error"],
        }

    user_msg = f"Package data: {json.dumps(pkg_data)}"
    if description:
        user_msg += f"\nAdditional description: {description}"

    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": _SYSTEM},
            {"role": "user",   "content": user_msg},
        ],
        response_format={"type": "json_object"},
    )

    try:
        result = json.loads(response.choices[0].message.content or "{}")
    except json.JSONDecodeError:
        result = {}

    # Validate condition value
    condition = result.get("condition", "unclear")
    if condition not in ALLOWED_CONDITIONS:
        condition = "unclear"

    return {
        "orderId":            order_id,
        "condition":          condition,
        "recommended_action": result.get("recommended_action", "Requires manual inspection."),
        "requires_approval":  bool(result.get("requires_approval", True)),
        "reasoning":          result.get("reasoning", ""),
    }
'@

Commit "feat(part8): complete PackageConditionChecker with HITL approval gate"

# ════════════════════════════════════════════════════════════════════════════
# Push all branches
# ════════════════════════════════════════════════════════════════════════════
Write-Host "Pushing all branches to origin…"
git -C $repo push origin main
git -C $repo push origin baselines/10-first-agent
git -C $repo push origin baselines/10-30-context-map
git -C $repo push origin baselines/11-spec
git -C $repo push origin baselines/12-mcp-design
git -C $repo push origin baselines/14-mcp-server
git -C $repo push origin baselines/15-agent-start
git -C $repo push origin baselines/15-agent
git -C $repo push origin baselines/16-a2a-start
git -C $repo push origin baselines/16-a2a
git -C $repo push origin baselines/17-hitl-start
git -C $repo push origin baselines/17-hitl

git -C $repo checkout main
Write-Host "Done. All branches created and pushed."
git -C $repo branch -a
