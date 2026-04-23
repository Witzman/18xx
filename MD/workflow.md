# Document supported Development with Claude Code

A description of a workflow for implementing a complex, rule-governed system
collaboratively with an AI coding assistant. The workflow is built around three
principles: **retrieving and tracking requirements from UseCases**, **keep Claude's context sharp**,
and **never let documentation go stale**.

---

## Setup

```
Windows 11 (host)
└── WSL2  (Linux environment — all development happens here)
    ├── VS Code (Remote-WSL extension — editor connects directly into WSL)
    ├── Docker Desktop (app runs in a container, served at localhost)
    └── ~/projects/
        ├── myproject/          ← project root (not a git repo itself)
        │   ├── myproject/      ← main git repo  (current working branch)
        │   ├── MD  →  symlink  ← always points to /home/user/myproject-docs/MD/
        │   └── CLAUDE.md →     ← always points to /home/user/myproject-docs/CLAUDE.md
        └── myproject-docs/     ← git worktree, locked to Documentation branch
            ├── MD/
            └── CLAUDE.md
```

**Why this stack?**
- WSL gives a full Linux environment without dual-booting; Docker keeps the app
  runtime isolated from the host.
- VS Code's Remote-WSL extension means the editor, terminal, and file system all
  live in the same Linux context — no path translation issues.
- The symlinks decouple the documentation layer from the code layer (see below).

---

## The Requirements Catalogue

The Use-case description is the authoritative source of truth. It is treated as
an **Requirements Catalogue** not as background reading.

The workflow starts by extracting the usecases into plain text and then decomposing
it into discrete, implementable **subtasks**. Each use case is:

- **Atomic** — it can be implemented and verified independently.
- **Requirements-referenced** — it cites the section of the Usecases it covers.
- **Layer-annotated** — it is tagged with the complexity tier it belongs to in the
  engine (see *Codebase Knowledge* below).

These use cases become the unit of work for every implementation session.

---

## Tracking: openpoints.md + done.md → status.md

Three files form a three-tier tracking system. All live in `MD/`.

### `MD/openpoints.md` — the backlog

All **pending** use cases, grouped by feature area. Each item is a checkbox:

```markdown
## 1. example

- [ ] **1.1** Description1 **[L2]**
- [ ] **1.2** Description2 **[L1]**
- [ ] **1.3** Description3 **[L2/L3]**
```

Layer annotations (`[L1]`, `[L2]`, `[L3]`) tell Claude (and you) how much new code
is needed before even starting a session.

### `MD/done.md` — the completed log

Completed use cases, copied from `openpoints.md` when finished. Each item gets a
plain-language description of *what was implemented* — written for rules, not code:

```markdown
- [x] **1.1** Description1 — Details **[L2]**
```

### `MD/status.md` — the merged view

A **combined, read-only** view that merges `openpoints.md` and `done.md` into a
single document using `[x]` / `[~]` / `[ ]` checkboxes. It is the 2nd file
Claude reads in a session after CLAUDE.md.

The split-then-merge pattern matters: `openpoints.md` stays short and actionable;
`done.md` provides the implementation history; `status.md` provides the complete
picture in one read for context-setting at the start of a conversation.

---

## Codebase Knowledge: ENGINE_MECHANICS.md and ABILITIES_REFERENCE.md

Before implementing anything, the **engine patterns** are extracted once and stored
as reference documents. This means Claude never has to rediscover how the engine
works mid-session.

### `MD/ENGINE_MECHANICS.md`

Documents the engine's implementation layer taxonomy and method-override patterns.
A new mechanic can be placed in the right layer immediately:

```
Layer 1 — constants only
Layer 2 — named Project::Base methods or overrides
Layer 3 — new concepts to be added
Layer 4 — structural engine divergence (rare; avoid if possible)
```

Also documents:  step sequence for concepts, event handler naming conventions,
how FE works, edge cases, and other non-obvious engine invariants.

### `MD/ABILITIES_REFERENCE.md`

A frequency table and field reference for all methods in the engine. Before 
implementing a new method, this file shows which methods can be used, which 
fields are required, etc.

**The payoff**: Claude can plan and implement a mechanic without reading hundreds of
engine source files. The reference docs carry the "what does the engine support"
knowledge forward across sessions.

---

## Documentation Always Available: the git.md Approach

**The problem**: documentation committed to a feature branch disappears when you
switch to a different branch. Checking it out on every branch creates merge noise.

**The solution**: a dedicated `Documentation` branch backed by a **git worktree**
and exposed via a **symlink** that lives *outside* the git repo.

```bash
# One-time setup:
git -C ~/projects/myproject/myproject worktree add \
    /home/user/myproject-docs Documentation

ln -s /home/user/myproject-docs/MD \
    ~/projects/myproject/MD

ln -s /home/user/myproject-docs/CLAUDE.md \
    ~/projects/myproject/CLAUDE.md
```

Key properties:

| Property | Why it matters |
|---|---|
| Worktree shares the `.git` object store | No second clone to keep in sync |
| Symlink lives in the project root, outside the git repo | Invisible to all branches; never committed |
| `Documentation` branch contains only docs | No risk of accidentally merging docs into code |
| Edit via symlink path | Transparent — no special paths to remember |
| Commit from the worktree directory | One place to commit docs, regardless of code branch |

The result: `MD/` and `CLAUDE.md` are always accessible at the same path, on every
branch, without any branch-switching or stash operations.

---

## How a Session Works

1. **Orient** — read `MD/status.md` to establish current state.
2. **Select** — pick one or two use cases from `openpoints.md` based on priority
   and layer cost.
3. **Consult** — read the relevant section of `ENGINE_MECHANICS.md` or
   `ABILITIES_REFERENCE.md` if the mechanic touches engine patterns.
4. **Implement** — code the use case. Keep scope tight: one use case per session
   unless items are trivially coupled.
5. **Update** — move the item from `openpoints.md` to `done.md`; update `status.md`.
6. **Commit docs** separately from code (from the `myproject-docs/` worktree).

---

## CLAUDE.md — The Session Briefing Document

`CLAUDE.md` is the single file Claude reads at the start of every session. Its job is
to eliminate re-orientation cost: Claude should know what the project is, where to
look, how the engine works, and what the current state is — before the first prompt
is typed.

It is not a README for humans. It is a **context bootstrap for Claude**, written at
the level of detail an experienced contributor would need after a two-week absence.

Because `CLAUDE.md` is a symlink into the `Documentation` worktree (see *Documentation
Always Available* above), it is always present and always current, regardless of which
code branch is active.

---

### Intent

The sections form a deliberate reading order:

1. *Overview* — what am I working on?
2. *File locations* — where do I look?
3. *Physical setup* — how is the project organised?
4. *Implementation status* — what state am I in?
5. *Architecture summary* — which layer does my next task belong to?
6. *Domain rules* — what are the correct facts to reason from?
7. *Milestones* — what is the next task?

A session starts by reading `CLAUDE.md`. After that, Claude has enough context to
pick the right files, apply the right patterns, and stay within scope — without
asking orientation questions or reading the full source tree.

---


### Layout

#### 1. Project Overview

One paragraph: what is this system, what technology does it run on, and what is the
scope of the current work. Includes pointers to the authoritative requirements source
and any out-of-scope variants.

```markdown
## Project Overview

This repo contains the **Acme** engine (a Python/FastAPI service) with an in-progress
implementation of **WidgetFlow**, a workflow automation module.

- **Engine source**: `acme/` — the main application codebase
- **Spec document**: `specs/widgetflow_spec_v2.pdf` and extracted `specs/widgetflow_spec_v2.txt`
- **Focus on WidgetFlow full module — no changes to WidgetFlow Lite**
```

---

#### 2. Key File Locations

A lookup table: concept → path. Claude uses this instead of searching the tree.
Include every file that Claude might need to open in a typical session.

```markdown
## Key File & Path Locations

| What | Path |
|---|---|
| Backend | `acme/backend/` |
| Frontend | `acme/frontend` |
| Assets | `acme/Assets/` |
| Spec PDF + TXT | `specs/` |
| Open points list | `MD/openpoints.md` |
| Engine mechanics ref | `MD/ENGINE_MECHANICS.md` |
| API reference | `MD/API_REFERENCE.md` |
| Git/docs setup | `MD/git.md` |
```

---

#### 3. Physical Setup and Documentation Index

Explains the directory structure, the git remotes, and what each `MD/` file is for.
This section is the bridge between the file-location table and the worktree/symlink
setup documented in `MD/git.md`.

```markdown
## Reference Documents in MD/

### Physical Setup

~/projects/
    myproject/           ← project root (not a git repo)
        myproject/       ← main git repo
        MD  →  symlink   ← always points to myproject-docs/MD/
        CLAUDE.md →      ← always points to myproject-docs/CLAUDE.md
    myproject-docs/      ← git worktree, Documentation branch

### MD/ File Index

| File | Purpose |
|---|---|
| `MD/ENGINE_MECHANICS.md` | Backend, Frontend, etc |
| `MD/API_REFERENCE.md` | All 20 hook types, field reference, frequency table |
| `MD/openpoints.md` | Pending use cases with layer annotations |
| `MD/git.md` | Worktree/symlink setup, how to commit docs |
| `CLAUDE.md` | This file |
```

---

#### 4. Implementation Status

A high-level percentage, a bullet list of what works, and a bullet list of what is
missing. The *missing* list points to the relevant `openpoints.md` section so Claude
can drill down without reading the whole backlog.

```markdown
## Implementation Status: ~40% Complete (Alpha)

- Core engine starts without errors
- Basic widget CRUD operations work
- Approval workflow scaffold in place

### What Is Implemented
- Entity definitions for all 12 widget types
- REST endpoints for create/read/update/delete
- Role-based access control (admin + editor)

### What Is Missing
- **Notification hooks** — stub only, no delivery
- **Tests** — zero coverage for WidgetFlow module
```

---

#### 5. Architecture Summary

A condensed version of the layer taxonomy from `ENGINE_MECHANICS.md`. Just enough
for Claude to place a new mechanic in the right layer without reading the full
reference document first.

```markdown
## Engine Architecture

**Layer 1** — constants only
**Layer 2** — named Project::Base methods or overrides
**Layer 3** — new concepts to be added
**Layer 4** — structural engine divergence (rare; avoid if possible)
```

---

#### 6. Domain Rules Summary

Distilled facts from the requirements catalogue — only what Claude needs to reason
correctly about the domain. Not a copy of the spec; a curated cheat sheet.

Tables work well here: entity types and their properties, phase transitions, cost
tables, movement rules. Each table replaces several pages of prose.

```markdown
## Domain Rules Summary

### Entity Types

| Type | Max instances | Lifecycle | Conversion |
|---|---|---|---|
| Widget A | 12 | Created → Active → Archived | Can become Widget B at Phase 3 |
| Widget B | 6 | Created → Active | Terminal |

### Approval Phases

| Phase | Approvers required | Timeout |
|---|---|---|
| Draft | 1 (author) | None |
| Review | 2 (any editor) | 48h |
| Publish | 1 (admin) | 24h |
```

---

#### 7. Development Notes and Next Milestones

Engine conventions that don't fit the layer taxonomy, variant inheritance notes,
test location, and the next 3–5 priority items. The milestone list is a quick
decision aid: it tells Claude what is most foundational without requiring a full
read of `openpoints.md`.

```markdown
## Development Notes

- Engine follows the Acme plugin pattern; see `acme/DEVELOPMENT.md`
- Lite variant extends base via inheritance — do not modify base for Lite-only fixes
- Tests live in `acme/spec/`; WidgetFlow currently has none

### Next Milestones (priority order)

1. **Approval routing** — implement dispatch logic in `step/approve.py`
2. **Notification hooks** — wire `on_approve` / `on_reject` events
3. **Revenue calculation** — override `calculate_revenue` for Widget B rules
```

---

## Future Ideas to Try

### Context and prompting
- **Structured session opener** — a standard prompt template that loads
  `status.md`, specifies the target use case, and states the layer. Reduces the
  "re-orient" overhead at the start of every session.
- **CLAUDE.md hooks** — automate recurring behaviours (e.g. "after each edit,
  check that the app still starts") by adding hook entries to `settings.json`
  rather than relying on memory.
- **Per-file intent comments** — a one-line header comment in each game file
  describing its role. Helps Claude navigate without reading every file top-to-bottom.

### Tracking and review
- **`/ultrareview` on feature branches** — run a multi-agent cloud review before
  merging a feature branch. Useful for catching unintended regressions across the
  engine.
- **`MD/decisions.md`** — a lightweight Architecture Decision Record (ADR) log.
  Each entry: the decision, the alternative considered, and why it was rejected.
  Prevents re-litigating the same questions across sessions.
- **Git notes** for per-commit context — `git notes add -m "reason: ..."` attaches
  free-form notes to commits without touching the commit message. Useful for
  recording *why* an unusual implementation choice was made.

### Workflow automation
- **Pre-commit hook** that runs the app's startup check (`ruby app.rb --check` or
  equivalent). Catches parse errors before they land in git history.
- **GitHub Actions** — even a minimal CI job that boots the app and runs the test
  suite on every push to a feature branch. Turns "it starts locally" into "it
  starts everywhere."
- **Makefile or `justfile`** — a small set of named commands (`make run`,
  `make test`, `make check`) so Claude can invoke them without knowing Docker
  flags or port numbers.

### AI-assisted documentation
- **Auto-generate `done.md` entries** — after each implementation session, ask
  Claude to draft the `done.md` entry in the same rules-based style as the
  existing entries. Review and paste; don't write from scratch.
- **Diff-driven status updates** — give Claude `git diff main..HEAD` and ask it
  to identify which `openpoints.md` items the diff closes. Reduces the risk of
  forgetting to update tracking files.
