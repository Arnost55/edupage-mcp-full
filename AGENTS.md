# AGENTS.md — edupage-mcp-full

Guidance for AI agents (and humans) working on this repository. This file is
about **maintaining the code** — it is *not* end-user runtime documentation
(that lives in [README.md](README.md)).

## What this project is

A stdio Model Context Protocol (MCP) server that exposes the Python
[`edupage-api`](https://github.com/EdupageAPI/edupage-api) library as MCP tools.
Published to PyPI as **`edupage-mcp-full`**; the GitHub repo is the canonical
source.

**Architecture rule:** this repo is deliberately a **thin wrapper** around
`edupage-api`. All EduPage endpoint/parsing/login complexity belongs upstream,
not here. When a feature breaks, check `edupage-api` first before reimplementing
logic. Do not grow a scraping layer here.

## Layout

| Path | Purpose |
|---|---|
| `src/edupage_mcp/__init__.py` | **The whole server**: all tools + `main()`. |
| `src/edupage_mcp/__main__.py` | `python -m edupage_mcp` entry. |
| `pyproject.toml` | Packaging; console script `edupage-mcp-full = "edupage_mcp:main"`. |
| `README.md` | End-user docs (install, usage, tools). |
| `requirements.txt` | Dev install (`-e .`). |

## Conventions (keep these consistent)

- **One file.** All tools live in `__init__.py`. Keep it that way unless it
  becomes unmanageable.
- **Every tool** is a function decorated with `@_tool` and defined as:
  ```python
  @_tool
  def my_tool(arg: str = None, subdomain: str = None) -> dict:
      """Description. Note if it mutates EduPage state (Writes: X)."""
      def go():
          client = _require_client(subdomain)
          ...
          return {...}
      return _run(go, "my_tool")
  ```
  - `_tool` registers the fn with FastMCP when MCP is installed, else keeps it
    callable for tests.
  - `_run` wraps exceptions → returns `{"isError": True, ...}` (JSON-RPC result).
  - Sub-tools that need parsing helpers should reuse `_serialize`, `_parse_date`,
    `_resolve_target`, `_find_child` rather than reimplementing.
- **Read-only vs write.** `get_*` tools read only. Tools that send messages,
  order meals, or switch accounts write — say so in the docstring, and mark in
  the README tool table.
- **Multi-school state.** Sessions are keyed by subdomain:
  ```python
  _clients = {}          # subdomain -> Edupage
  _two_factor = {}       # subdomain -> TwoFactorLogin
  _active_subdomain = None
  ```
  Every data tool takes an optional `subdomain` and resolves through
  `_require_client(subdomain)` (falls back to `_active_subdomain`).
- **JSON output.** Return plain JSON serialisable via `_serialize` (handles
  dataclasses, enums, `datetime`). Don't return raw `edupage-api` objects.

## Dependency pinning

`pyproject.toml` pins `mcp<2`. Reason: `mcp 2.x` renamed `FastMCP` → `MCPServer`
and changed the API. We target the FastMCP v1 API. Keep `mcp<2`. Bump
`edupage-api` as needed (it can rise freely).

## Build / verify

```bash
# from repo root — install once
uv sync            # or: python -m venv .venv && .venv/bin/python -m pip install -e .

# sanity: compile + list tools over a real MCP handshake
python -m py_compile src/edupage_mcp/__init__.py
python -m edupage_mcp     # then drive an MCP client; tools/list should show all
```

There is no test suite; a manual MCP `tools/list` after any addition is the
verification step. After adding/renaming a tool, update the README "Tool
reference" table and the tool count in the "What it provides" blurb.

## After changing this repo

- Bump `version` in `pyproject.toml` before publishing to PyPI.
- Rebuild + publish with `uv build` / `uv publish` (or `python -m build` +
  `twine upload`).
- Keep the README accurate (install, tools, counts).
