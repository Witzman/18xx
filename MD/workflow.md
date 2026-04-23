# Use Case Driven Development with Claude Code

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
