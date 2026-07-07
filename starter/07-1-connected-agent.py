"""Part 7 — First MCP-connected agent (starter).

Follow the lab steps in docs/segments/07-agent-framework-and-first-mcp-agent.md
to complete each TODO below.

Lab steps summary:
  1. DONE  Imports and OpenAI client below are ready.
  2. TODO  Add INSTRUCTIONS (role, boundaries, grounding rule, escalation).
  3. TODO  In run_agent: connect to the MCP server and list available tools.
  4. TODO  In run_agent: implement the tool-calling loop.
  5. TODO  Wire show_steps to print each tool call number, name, args, and result.
  6. TEST  Try --order DM-9999 and name one case where the agent should escalate.

Uses mcp_server.py from the workshop root when present; falls back to packagemcp.

Run:
    python starter/07-1-connected-agent.py --order DM-1037
    python starter/07-1-connected-agent.py --order DM-1037 --show-steps

Compare with the completed version at baseline/07-1-connected-agent.py.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from openai import AzureOpenAI

load_dotenv()

# -- MCP server ---------------------------------------------------------------
_ROOT = Path(__file__).parent.parent  # workshop/
_SERVER_FILE = _ROOT / "mcp_server.py"

# Uses mcp_server.py built in Part 6 when present; falls back to packagemcp.
if _SERVER_FILE.exists():
    SERVER_PARAMS = StdioServerParameters(
        command=sys.executable,
        args=[str(_SERVER_FILE)],
    )
else:
    SERVER_PARAMS = StdioServerParameters(
        command=sys.executable,
        args=["-m", "packagemcp"],
        env={**os.environ, "PYTHONPATH": str(_ROOT)},
    )

# -- Azure OpenAI client ------------------------------------------------------
client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_KEY"],
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
)
MODEL = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-5.5")

# TODO (step 2): Replace this placeholder with a real INSTRUCTIONS string that defines:
#   - Role      : who the agent is and what it helps with
#   - Allowed   : what actions it may take (look up package/order/route, propose next step)
#   - Boundaries: what it must never claim or do
#   - Grounding : every factual claim must trace to a tool result
#   - Escalation: when to ask for clarification instead of guessing
INSTRUCTIONS = "TODO: add role, allowed actions, boundaries, grounding rule, and escalation"


async def run_agent(question: str, show_steps: bool = False) -> None:
    # TODO (step 3): Open a stdio_client connection to SERVER_PARAMS, initialise the
    # ClientSession, and call session.list_tools() to get the available tools.
    # Convert each MCP tool to the OpenAI {"type": "function", "function": {...}} shape.

    # TODO (step 4): Build the messages list with INSTRUCTIONS as the system message
    # and question as the first user message, then loop:
    #   a. Call client.chat.completions.create with the tools list and tool_choice="auto".
    #   b. Append the model's message to messages.
    #   c. If the message has tool_calls: dispatch each via session.call_tool,
    #      append the tool result as a "tool" role message, and continue.
    #   d. If no tool_calls: print the final answer and break.

    # TODO (step 5): When show_steps is True, print a numbered trace:
    #   "{n}) calling {tool_name}({args})"
    #   "   -> {result}"

    print("TODO: implement run_agent — see lab steps 3-5")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Dunder Mifflin connected agent")
    parser.add_argument("--order", default="DM-1037", help="Package/order ID to investigate")
    parser.add_argument("--show-steps", action="store_true", help="Print each tool call and result")
    args = parser.parse_args()
    asyncio.run(
        run_agent(
            f"What should I do with order {args.order}?",
            show_steps=args.show_steps,
        )
    )
