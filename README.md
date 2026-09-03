# edupage-mcp

A Model Context Protocol (MCP) server that exposes the full functionality of the
[`edupage-api`](https://github.com/EdupageAPI/edupage-api) Python library to AI
agents such as opencode, Claude, Cursor and any other MCP client.

EduPage is a school information system used across Europe. This server lets you
query and operate a student / teacher / parent EduPage account directly from
your agent: timetables, grades, homework, substitutions, meals (including
ordering), messages, rosters, parent child-switching and more.

> **⚠️ Unofficial API.** Like all EduPage MCP servers, this relies on the
> community-maintained [`edupage-api`](https://github.com/EdupageAPI/edupage-api)
> library, which talks to EduPage's undocumented endpoints. Use read-only
> features freely; use the write features (`send_message`, meal ordering, child
> switching) carefully.

---

## Table of Contents

- [Why another EduPage MCP server?](#why-another-edupage-mcp-server)
- [What it provides](#what-it-provides)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [1. Install](#1-install)
  - [2. Configure credentials](#2-configure-credentials)
  - [3. Register with your MCP client](#3-register-with-your-mcp-client)
- [Usage examples](#usage-examples)
- [Multiple schools (subdomains)](#multiple-schools-subdomains)
- [Tool reference](#tool-reference)
- [Data & safety notes](#data--safety-notes)
- [Architecture & implementation](#architecture--implementation)
- [Limitations](#limitations)
- [License](#license)

---

## Why another EduPage MCP server?

Two other EduPage MCP servers already exist:

- [`mrtineu/edupage-mcp`](https://github.com/mrtineu/edupage-mcp) — also
  published on PyPI as [`edupage-mcp`](https://pypi.org/project/edupage-mcp/)
- [`mhlavac/edupage-mcp`](https://github.com/mhlavac/edupage-mcp)

Both are good and I have **no affiliation** with them — they are simply
referenced here for honest comparison. They primarily focus on the **read-only**
surface of the API.

This project deliberately goes further:

| Capability | mhlavac | mrtineu (PyPI) | **this project** |
|---|---|---|---|
| Timetables (own + any teacher/class/room) | ✅ | ✅ | ✅ |
| Grades (all / by term & year) | ✅ | ✅ | ✅ |
| Substitutions / timetable changes | ✅ | ✅ | ✅ |
| Meals — **read menu** | ✅ | ✅ | ✅ |
| Meals — **choose / sign-off / rate** | ❌ | ❌ | ✅ |
| Send messages (`send_message`) | ✅ | ❌ | ✅ |
| Parent **child switching** (switch to/from child) | partial (list) | ❌ | ✅ |
| **2FA** login flow (device + email code) | ❌ | ❌ | ✅ |
| Login via **session id** (`PHPSESSID`) | ❌ | ❌ | ✅ |
| Portal login (`login_auto`) | ✅ | ❌ | ✅ |
| Next ringing time / bell schedule | ❌ | ❌ | ✅ |
| Raw session **custom request** | ❌ | ❌ | ✅ |
| **Multiple schools** in one session | ❌ | ❌ | ✅ |

In short:

- **For read-only use** (timetables, grades, notifications) this project is on
  par with the others, and it reuses the same underlying `edupage-api` library,
  so data reliability is identical.
- **For the full feature set** — writing messages, ordering meals, parent
  child-switching, 2FA, session-id login, multi-school — only this project
  covers everything the `edupage-api` actually exposes.

It is also designed to be **opencode-first**: it follows the same conventions
as your other local MCP servers (stdio transport, JSON text output, `auth_status`,
env-var credentials) so it slots into your existing setup without surprises.

---

## What it provides

A single stdio MCP server (`edupage_mcp.py`) exposing **39 tools**:

- **Authentication** — `login`, `login_auto`, `login_all`, `login_from_session`,
  `two_factor_check_confirmed`, `two_factor_finish`, `auth_status`, `user_id`
- **Timetables** — `get_my_timetable`, `get_timetable` (teacher/student/class/
  classroom), `get_next_week_timetable`, `get_next_ringing_time`, `get_periods`,
  `school_year`
- **Grades** — `get_grades`
- **Notifications / timeline** — `get_notifications`, `get_notification_history`,
  `get_homework`, `get_assignments`, `get_absences`, `get_upcoming_events`, `get_news`
- **Substitutions** — `get_timetable_changes`, `get_missing_teachers`
- **Meals** — `get_meals`, `choose_meal`, `sign_off_meal`, `rate_meal`
- **Rosters** — `get_students`, `get_all_students`, `get_teachers`, `get_classes`,
  `get_classrooms`, `get_subjects`, `get_my_children`
- **Actions** — `send_message`, `switch_to_child`, `switch_to_parent`, `custom_request`

---

## Getting started

### Prerequisites

- Python **3.9+** (Python 3.14 on Windows is verified)
- A [GitHub](https://github.com) account only if you want the repo; not needed to run.
- An MCP-capable client (opencode, Claude Desktop, Cursor, etc.)

### 1. Install

```bash
git clone https://github.com/oliverhruby/edupage-mcp.git
cd edupage-mcp
python -m venv .venv
# Windows
.venv\Scripts\python -m pip install -r requirements.txt
# macOS / Linux
.venv/bin/python -m pip install -r requirements.txt
```

> `requirements.txt` pins `mcp<2` (the stable FastMCP v1 API). `mcp 2.x`
> renamed `FastMCP` to `MCPServer` and changed the API surface; this server
> targets the FastMCP v1 API for simplicity and stability.

### 2. Configure credentials

Either set environment variables **or** pass credentials to `login` (see
[Usage](#usage-examples)).

```bash
# Windows (persistent, per-user)
setx EDUPAGE_USERNAME "your_username"
setx EDUPAGE_PASSWORD "your_password"
setx EDUPAGE_SUBDOMAIN "your_school"   # https://your_school.edupage.org

# macOS / Linux
export EDUPAGE_USERNAME="your_username"
export EDUPAGE_PASSWORD="your_password"
export EDUPAGE_SUBDOMAIN="your_school"
```

`EDUPAGE_SUBDOMAIN` is the single-subdomain case. For **multiple schools** see
[Multiple schools](#multiple-schools-subdomains).

### 3. Register with your MCP client

**opencode** — add to `~/.config/opencode/opencode.json` (or `opencode.jsonc`):

```jsonc
{
  "mcp": {
    "edupage": {
      "type": "local",
      "enabled": true,
      "command": [
        "C:/Users/YOU/dev/edupage-mcp/.venv/Scripts/python.exe",
        "C:/Users/YOU/dev/edupage-mcp/edupage_mcp.py"
      ],
      "env": {
        "EDUPAGE_USERNAME": "{env:EDUPAGE_USERNAME}",
        "EDUPAGE_PASSWORD": "{env:EDUPAGE_PASSWORD}",
        "EDUPAGE_SUBDOMAIN": "{env:EDUPAGE_SUBDOMAIN}"
      }
    }
  }
}
```

**Claude Desktop / Cursor** — use `claude_desktop_config.json` /
`.mcp.json` with a `mcpServers` entry in the standard shape, pointing
`command`/`args` at the venv python and the `edupage_mcp.py` path, plus an
`env` block with your credentials.

After editing client config, **restart the client** so the MCP server is loaded.

---

## Usage examples

```text
# Check the MCP is alive and see which schools are logged in
auth_status

# Log in (uses env vars, or pass explicit args)
login

# If 2FA is enabled:
two_factor_check_confirmed        # approve on device -> True
two_factor_finish                 # then finish

# Your own timetable for today
get_my_timetable

# Timetable for a specific class on a date
get_timetable target_type="class" target_id="9.A" date_str="2026-09-10"

# Next week's timetable
get_next_week_timetable

# Grades (all, or for a term/year)
get_grades
get_grades term="FIRST" year=2026

# Substitutions / changes for today
get_timetable_changes

# Meal menu and order lunch (option #2)
get_meals
choose_meal date_str="2026-09-10" meal_type="lunch" number=2

# Who is in the school + send a message to a teacher
get_teachers
send_message recipient_id="Teacher456" body="Hello!"

# Parent account: see children, then switch to one
get_my_children
switch_to_child child_id=123
get_my_timetable
switch_to_parent
```

---

## Multiple schools (subdomains)

Each subdomain (school) keeps its **own** logged-in session. Use `login_all`
to authenticate several schools at once, then pass `subdomain` to any data tool
(it defaults to the last active subdomain when omitted):

```text
login_all subdomains="zsskola1,zsskola2" usernames="u1,u2" passwords="p1,p2"

get_my_timetable subdomain="zsskola1"
get_my_timetable subdomain="zsskola2"
auth_status          # shows all logged-in subdomains + which is active
```

You can also call `login` once per school to add/lookup sessions incrementally.

> `EDUPAGE_SUBDOMAIN` env var covers a single school only. For two or more
> schools use `login_all` or repeated `login` calls.

---

## Tool reference

| Tool | Description | Writes? |
|---|---|---|
| `login` | Log in with username/password/subdomain (env vars supported) | ✅ session |
| `login_auto` | Log in via the EduPage portal (auto-detect school) | ✅ session |
| `login_all` | Log in to multiple schools in one call | ✅ session |
| `login_from_session` | Create a session from an existing `PHPSESSID` cookie | ✅ session |
| `two_factor_check_confirmed` | Check if 2FA was approved on a device |  |
| `two_factor_finish` | Finish 2FA (email/app code or device confirmation) | ✅ session |
| `auth_status` | Which subdomains are logged in + active one |  |
| `user_id` | Logged-in user id |  |
| `school_year` | Current school year |  |
| `get_my_timetable` | Logged-in user's timetable for a date |  |
| `get_timetable` | Timetable of a teacher/student/class/classroom |  |
| `get_next_week_timetable` | Mon–Fri timetable for next week |  |
| `get_next_ringing_time` | Next bell (break/lesson) at a given time |  |
| `get_periods` | Bell schedule (period start/end times) |  |
| `get_grades` | Grades, optionally by year & term |  |
| `get_notifications` | Timeline notifications |  |
| `get_notification_history` | Timeline notifications since a date |  |
| `get_homework` | Homework from the timeline |  |
| `get_assignments` | Homework/tests/exams from the timeline |  |
| `get_absences` | Absence records from the timeline |  |
| `get_upcoming_events` | Trips/excursions/meetings/holidays |  |
| `get_news` | School news |  |
| `get_timetable_changes` | Substitutions / timetable changes for a date |  |
| `get_missing_teachers` | Teachers missing on a date |  |
| `get_meals` | Meal menu (snack/lunch/afternoon snack) |  |
| `choose_meal` | Order a meal | ✅ |
| `sign_off_meal` | Cancel an ordered meal | ✅ |
| `rate_meal` | Rate a meal (quality/quantity) | ✅ |
| `get_students` | Students in the logged-in user's class |  |
| `get_all_students` | All students in the school (short list) |  |
| `get_teachers` | All teachers |  |
| `get_classes` | All classes |  |
| `get_classrooms` | All classrooms |  |
| `get_subjects` | All subjects |  |
| `get_my_children` | Parent's children / student's classmates |  |
| `send_message` | Send a message to a user | ✅ |
| `switch_to_child` | Switch to a child account (parent only) | ✅ session |
| `switch_to_parent` | Switch back to the parent account | ✅ session |
| `custom_request` | Raw request through the active session (GET/POST) | ✅ |

---

## Data & safety notes

- Most tools are **read-only**. The ones marked **Writes? ✅** mutate EduPage
  state (sent messages, ordered meals, switched accounts). Use them with care.
- `get_homework`, `get_assignments`, `get_absences`, `get_upcoming_events` and
  `get_news` derive their data from the **timeline notifications** — if the
  school doesn't push certain event types, those tools may return empty lists.
- `get_missing_teachers` is marked **experimental** upstream (parses HTML from
  the substitution page) and can raise if a teacher's name no longer matches.
- Meal `rate_meal` and ordering depend on the school publishing menus with the
  matching identifiers; not all schools expose ratings.

---

## Architecture & implementation

### High-level design

```
MCP client (opencode / Claude / Cursor ...)
        │  stdio JSON-RPC
        ▼
edupage_mcp.py  (FastMCP server, mcp<2)
        │  thin, stateless-per-tool facade
        ▼
edupage-api  (community library, all the EduPage endpoint work)
        ▼
EduPage web services (HTTPS, undocumented endpoints)
```

This project is deliberately a **thin wrapper**: 95% of the hard, volatile work —
EduPage's undocumented/non-public endpoints, the login flow, 2FA, HTML/JSON
parsing — lives in the battle-tested [`edupage-api`](https://github.com/EdupageAPI/edupage-api)
library. Our job is to expose that library over MCP cleanly, correctly
serialise its data model, and make multi-school + write operations ergonomic.

### Key files

| File | Role |
|---|---|
| `edupage_mcp.py` | The entire MCP server (single file, stdio transport). |
| `requirements.txt` | Pinned deps: `mcp<2` and `edupage-api>=0.12.3`. |

### Session & state management

The server keeps **one `Edupage()` client per subdomain** in a dict:

```python
_clients = {}          # subdomain -> Edupage
_two_factor = {}       # subdomain -> TwoFactorLogin (pending 2FA)
_active_subdomain = None
```

Every data tool resolves its client with `_require_client(subdomain)`:

```python
def _require_client(subdomain=None):
    sub = subdomain or _active_subdomain
    client = _clients.get(sub)
    if client is None or not client.is_logged_in:
        raise RuntimeError(f"Not logged in for subdomain '{sub}' ...")
    return client
```

This is what makes **multiple schools** possible in a single server process —
each `login`/`login_all` call adds or replaces that subdomain's session instead
of clobbering a single global client. When `subdomain` is omitted, tools fall
back to the last subdomain that logged in.

### 2FA flow

`edupage-api` returns a `TwoFactorLogin` object when a second factor is
required. We keep it keyed by subdomain and expose two controls:

- `two_factor_check_confirmed` → polls EduPage to see if the confirmation was
  approved on a device.
- `two_factor_finish` → either `finish()` (device-confirmed) or
  `finish_with_code(code)` (email/app code).

### Serialisation

`edupage-api` returns rich dataclasses (`Lesson`, `EduGrade`, `TimelineEvent`,
`Meal`, `EduStudent`, …) containing nested enums, `datetime`/`time` objects and
sub-objects. A generic `_serialize()` converts them to plain JSON:

- `datetime` / `date` / `time` → `isoformat()`
- `Enum` → `.value`
- `dataclass` → dict of fields (skipping private `__` fields)
- `dict` / `list` / tuple → recursive
- fallback → `str()`

This keeps tool output consistent, human-readable and JSON-serialisable so any
MCP client can render it without importing `edupage-api`.

### Error handling

Each tool runs through `_run(..., error_label)`, which:

1. Catches `edupage_api` exceptions (e.g. `BadCredentialsException`,
   `NotLoggedInException`, `CaptchaException`, `SecondFactorFailedException`,
   `InvalidChildException`).
2. Returns a JSON-RPC result with `isError: true` and a friendly message that
   includes the exception type and message, so the agent can tell the user what
   went wrong instead of crashing.

### Dependency isolation (optional but recommended)

The server uses Python-only deps. To avoid clashing with an unrelated global
`mcp` install (e.g. a newer v2.x), it is recommended to run it from its own
virtualenv pinned to `mcp<2` — see [Install](#1-install).

---

## Limitations

- **Unofficial/read-mostly by design.** EduPage can change its endpoints at any
  time; reliability ultimately depends on `edupage-api`, not this wrapper.
- **No CAPTCHA bypass.** If EduPage presents a CAPTCHA during login, log in via
  browser first, then use `login_from_session` with the resulting `PHPSESSID`.
- **2FA requires human interaction** (approve on device or provide a code).
- **Parent/teacher accounts** are only partially verified upstream; some parent
  methods are best-effort.
- The auth session lives for the lifetime of the MCP server process; restarting
  the client means logging in again.

---

## License

[MIT](LICENSE) © Oliver Hrubý

This project is **not affiliated with or endorsed by** Ascora (EduPage) or by
the authors of `edupage-api`. EduPage is a registered trademark of its
respective owner(s).
