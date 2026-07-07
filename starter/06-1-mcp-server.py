"""Part 6 — Build the MCP server (starter).

Follow the lab steps in docs/segments/06-build-the-mcp-server.md to
implement each TODO below.

When done, validate standalone:
    mcp dev starter/06-1-mcp-server.py        # open MCP Inspector in the browser
    python starter/06-1-mcp-server.py         # verify it starts without errors (Ctrl+C to stop)

Compare with the completed version at baseline/06-1-mcp-server.py.
"""
import os

import httpx
from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP

load_dotenv()

_BASE_URL = os.getenv("PACKAGE_API_URL", "http://localhost:8000")
_PERSONA  = os.getenv("PACKAGE_API_PERSONA", "jim-halpert")

# The name is shown when a client or agent inspects this server.
mcp = FastMCP("package-manager")


def _get(path: str) -> dict | list | None:
    """GET from the package-this API. Returns None on 404."""
    r = httpx.get(
        f"{_BASE_URL}{path}",
        headers={"X-Persona-Id": _PERSONA},
        timeout=10.0,
    )
    if r.status_code == 404:
        return None
    r.raise_for_status()
    return r.json()


# --- Tools (callable functions the agent can invoke) -------------------------

@mcp.tool()
def list_packages() -> str:
    """Return all package IDs in the system. Use this to discover valid IDs before calling lookup_package or lookup_order_status."""
    # TODO: call _get("/packages"), extract the package IDs, and return them
    # as a comma-separated string — or "No packages found." when the list is empty.
    return "TODO"


@mcp.tool()
def lookup_package(package_id: str) -> str:
    """Look up a package by its ID (e.g. DM-1037).
    Returns status, destination, fragile flag, priority, and any delay information."""
    # TODO: call _get(f"/packages/{package_id}"), return "Error: no package found..." on None,
    # otherwise format and return the key fields.
    return "TODO"


@mcp.tool()
def lookup_order_status(package_id: str) -> str:
    """Return the current delivery status and delay details for a package (e.g. DM-1037). Read-only."""
    # TODO: call _get(f"/packages/{package_id}"), return status + any delay fields.
    return "TODO"


@mcp.tool()
def lookup_route(route_id: str) -> str:
    """Return route and driver information for a given route ID (e.g. R-2). Read-only."""
    # TODO: call _get(f"/routes/{route_id}"), return "Error: no route found..." on None,
    # otherwise return the route data as a string.
    return "TODO"


# --- Prompt (a reusable instruction template) --------------------------------

@mcp.prompt()
def investigate_delayed_package(orderId: str) -> str:
    """Reusable workflow for investigating a delayed or problematic package."""
    # TODO: return a step-by-step prompt string that instructs the agent to:
    # 1. list_packages, 2. lookup_package, 3. lookup_order_status,
    # 4. lookup_route (if route present), 5. check policy resource, 6. summarise.
    return f"TODO: prompt template for order {orderId}"


# --- Resource (read-only reference data) -------------------------------------

@mcp.resource("resource://package-status-policy")
def package_status_policy() -> str:
    """The Dunder Mifflin package handling and status policy."""
    # TODO: load data/policy.md from the workshop data folder and return its contents.
    # Hint: Path(__file__).parent / "data" / "policy.md"
    return "TODO: load from data/policy.md"


if __name__ == "__main__":
    mcp.run()
