"""Part 7 — First MCP-connected agent.

Connects to the Part 6 mcp_server.py and uses it to investigate package
orders and propose the next operational step for Darryl.

Uses mcp_server.py from the workshop root when it is present; falls back
to the pre-built packagemcp module if the attendee has not built it yet.

Run:
    python baseline/07-1-connected-agent.py --order DM-1037
    python baseline/07-1-connected-agent.py --order DM-1037 --show-steps
    python baseline/07-1-connected-agent.py --order DM-9999 --show-steps
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

INSTRUCTIONS = """\
You help Darryl, a warehouse lead, decide the next operational step for an incoming package or order.
Allowed actions: look up package, order, and route details through the package manager MCP server, then propose a next step.
Boundaries: never claim you physically moved, shipped, or rerouted anything; never act on real systems; only propose.
Grounding rule: base every factual claim on a tool result. If you have not looked something up, say so rather than guessing.
Escalation: if an order is missing a route or needs a manager's decision, ask for clarification rather than guessing.\
"""


async def run_agent(question: str, show_steps: bool = False) -> None:
    async with stdio_client(SERVER_PARAMS) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools_result = await session.list_tools()
            tools = [
                {
                    "type": "function",
                    "function": {
                        "name": t.name,
                        "description": t.description,
                        "parameters": t.inputSchema,
                    },
                }
                for t in tools_result.tools
            ]

            messages = [
                {"role": "system", "content": INSTRUCTIONS},
                {"role": "user", "content": question},
            ]

            step = 0
            while True:
                response = client.chat.completions.create(
                    model=MODEL,
                    messages=messages,
                    tools=tools,
                    tool_choice="auto",
                )
                msg = response.choices[0].message
                messages.append(msg)

                if msg.tool_calls:
                    for tc in msg.tool_calls:
                        step += 1
                        args = json.loads(tc.function.arguments)
                        if show_steps:
                            print(f"{step}) calling {tc.function.name}({args})")
                        result = await session.call_tool(tc.function.name, args)
                        tool_text = result.content[0].text if result.content else ""
                        if show_steps:
                            print(f"   -> {tool_text}")
                        messages.append({
                            "role": "tool",
                            "tool_call_id": tc.id,
                            "content": tool_text,
                        })
                else:
                    print(msg.content)
                    break


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
