# 18OE Project Optimization Audit

*Audit date: 2026-05-05. Scope: `CLAUDE.md` + every file in `MD/`, cross-checked against codebase structure under `18xx/lib/engine/game/g_18_oe/`.*

---

## TL;DR

The project has **good bones** — the workflow described in `workflow.md` is sound, the layer taxonomy in `ENGINE_MECHANICS.md` is genuinely useful, and `18OEstatus.md` is a strong status tracker. But three problems are dragging it down:

1. **Tracking files duplicate each other**, with conflicting [x]/[~]/[ ] states across `openpoints.md`, `done.md`, `working.md`, `18OEstatus.md`, and `openpointsread.md`. There is no single source of truth.
2. **Two `CLAUDE.md` files exist** (root and `MD/CLAUDE.md`) and they disagree.
3. **Several files contain conversation transcripts** (`bugs.md`) or stale meta-instructions (`dev_guide.md` §6) instead of curated reference content.

Fix those three and the project becomes much easier to navigate. Below: prioritized fixes.

---

## P0 — Critical fixes (do first)

### 1. Collapse the five tracking files into two

You currently have:

| File | Lines (rough) | Role | Source of truth? |
|---|---|---|---|
| `openpoints.md` | long | "open points" — but already contains `[x]` items | mixed |
| `done.md` | long | "implemented" — but stale (`18oe_fullmap`, 2026-04-23) | stale |
| `working.md` | ~535 | "implemented mechanics from rules POV" — duplicates `done.md` | stale |
| `18OEstatus.md` | ~723 | combined `[x]/[~]/[ ]` view, branch `18oe_testgame`, 2026-05-01 | **yes** |
| `openpointsread.md` | long | annotated copy of `openpoints.md` with rulebook quotes | will drift |

The `workflow.md` plan calls for `openpoints.md` (pending) + `done.md` (completed) → `status.md` (merged). What you actually have is five files with overlapping content and inconsistent dates.

**Recommendation:** keep two files only.

- **`18OEstatus.md` (rename to `status.md`)** — the merged `[x]/[~]/[ ]` view. Single source of truth.
- **`openpointsread.md`** — keep as a separate annotated companion since rule citations have value. But generate it *from* `status.md` (script or manual sync) rather than re-typing.

Delete `openpoints.md`, `done.md`, and `working.md`. Their content is already in `18OEstatus.md` (and where it disagrees, `18OEstatus.md` is newer).

**Concrete contradiction caught during this audit:**
- `working.md` §8 says: `[~] Two stale entries — A40 / E88 still in NATIONAL_REGION_HEXES`
- `18OEstatus.md` §2b says: `[x] Two stale entries removed: A40 from SC, E88 from RU`

You can't tell which is correct without looking at the code. That's exactly the failure mode duplicate trackers create.

### 2. Resolve the duplicate `CLAUDE.md`

Per `git.md`, `~/18xx/CLAUDE.md` is a symlink to `~/18xx-docs/CLAUDE.md`. But `MD/CLAUDE.md` also exists — a smaller, older draft that disagrees with the root one (different file index, different milestones, missing physical-setup section).

The MD/ version even references `MD/working.md` as "Implemented mechanics" while the root one references `MD/openpoints.md` as "Open points list" — neither is right, since the source of truth is `18OEstatus.md`.

**Recommendation:** delete `MD/CLAUDE.md` outright. There should be exactly one `CLAUDE.md` in this project, and it lives at the worktree root.

### 3. Update `CLAUDE.md`'s file index to point at the real source of truth

The root `CLAUDE.md` "Reference Documents in MD/" table currently lists `openpoints.md`, `mapquest.md`, `ENGINE_MECHANICS.md`, `ABILITIES_REFERENCE.md`, `git.md`, but **not `18OEstatus.md`** — the file that is actually the most up-to-date implementation tracker. The "Implementation Status" narrative section that *is* in `CLAUDE.md` is hand-maintained and will drift.

**Recommendation:** in `CLAUDE.md`, replace the hand-written "Implementation Status: ~55–60% Complete" bullet lists with a one-line pointer: *"Current state: see `MD/status.md`. Always read it first."* Keep CLAUDE.md as an orientation document, not a status snapshot.

### 4. Clean up `bugs.md`

`bugs.md` is currently a chat-session transcript: bullet markers are `●`, the file ends with `Ready to code?` and box-drawing characters (`╌╌╌╌╌`), text is wrapped at terminal width with trailing whitespace artifacts. It mixes findings, fixes, and conversational asides.

**Recommendation:** rewrite as a curated bug log. Format:

```markdown
## BUG-001 — can_buy? blocks non-presidents from secondary shares  [HIGH] [OPEN]
**File:** `step/buy_sell_par_shares.rb:60–72`
**Rule:** §8.3
**Symptom:** ...
**Fix:** ...
```

Then track resolved bugs the same way (`[FIXED 2026-05-XX commit abc123]`). When the file gets long, split into `bugs_open.md` / `bugs_resolved.md`.

---

## P1 — Documentation quality

### 5. `dev_guide.md` is half reference, half meta

§6 of `dev_guide.md` literally says *"Suggested Directory for This Guide: Create the file `MD/dev_guide.md` and include this content"* — that's a leftover instruction to whoever was creating the file. Delete it. The rest of the file overlaps significantly with `ENGINE_MECHANICS.md` (call sequence, layer taxonomy, extension hooks).

**Recommendation:** decide one of:
- merge `dev_guide.md` into `ENGINE_MECHANICS.md` and delete it, OR
- keep `dev_guide.md` as the *quick* cheat sheet and `ENGINE_MECHANICS.md` as the *deep* reference, with no overlap. State the split at the top of each.

Right now there's no clear difference between them, so contributors don't know which to read.

### 6. `Readme.MD` is empty

It contains only `Status:` and two image references. Either:
- Delete it (recommended — no value).
- OR turn it into the actual `MD/` index that humans land on first, with one-line descriptions of each MD file.

### 7. `workflow.md` describes an aspirational workflow

It's 418 lines of "here's the ideal workflow" but the project hasn't adopted parts of it (no `status.md` — file is `18OEstatus.md`; `openpoints.md` contains completed items). Either bring the project into alignment with the doc, or update the doc to match reality.

### 8. Add a missing "how to run" doc

There's nothing in `MD/` that tells a new contributor (human or Claude) how to:
- start the local 18xx server
- run a 18OE game in the browser
- run `rubocop` / lint
- run any tests that do exist

`workflow.md` mentions "Makefile or justfile" as a future idea. Just add a short `MD/commands.md` (or a Makefile) with the 5–10 commands you actually use. This is a 30-minute task with high payoff.

### 9. Add a decisions log

`workflow.md` lists `MD/decisions.md` as a "future idea" — make it real. Useful entries already implicit in the project:

- *Why £5,400/n + £2,600 for 2-player?* (Playbook §5.4 without-concessions formula)
- *Why is the Concession Phase deferred?* (Playbook §15)
- *Why use a `Set` for `@fulfilled_train_obligation` rather than `trains.empty?`* (BuyTrain §3.1)
- *Why does the engine reject ferry exits to blue hexes by default?* (openpoints §2.7)
- *Why is `WA-5` permanent rather than a fix-later?*

Each of these is rediscovered every time someone reads the code. A 1–2 sentence ADR per decision pays for itself fast.

---

## P2 — Workflow and process

### 10. Branch tracking is inconsistent across docs

- `working.md` says branch `18oe_fullmap`, last checked 2026-04-23
- `18OEstatus.md` says branch `18oe_testgame`, last checked 2026-05-01
- `openpoints.md` references multiple branches: `18oe_national`, `18oe_mergers`, `18oe_ports`, `18oe_testgame`

After collapsing tracking files (P0 #1), pin the source of truth to one branch (presumably `18oe_testgame`) and put the branch + commit hash + date at the top of `status.md`. Bump it every time you re-verify.

### 11. No CI / no pre-commit smoke test

Zero tests for 18OE is a known gap (every status file mentions it). A startup smoke test would give 80% of the value of full coverage:

```ruby
# spec/games/g_18_oe/smoke_spec.rb
describe Engine::Game::G18OE do
  it "initializes a 4-player game without errors" do
    expect { described_class.new(%w[A B C D]) }.not_to raise_error
  end
end
```

That alone catches 90% of accidental breakage during refactors. Wire it as a pre-commit hook so you can't push a broken game.

### 12. `coding_guidelines.txt` should be in MD/

`CLAUDE.md` says "Best practices are in `coding_guidelines.txt` in the main directory." But it's not symlinked into the docs worktree, so changes are tied to whichever code branch is checked out. Move it to `MD/coding_guidelines.md` (markdown, not txt) and reference it from `CLAUDE.md`'s file index.

---

## P3 — Code-level observations

(Not deep code review — just what the docs reveal.)

### 13. `BUG-1` through `BUG-4` in `bugs.md` are HIGH/MEDIUM and unresolved

- **BUG-1** (HIGH): `can_buy?` blocks non-presidents from secondary shares in Major Phase
- **BUG-2** (HIGH): `@bought` ivar is dead reference — pre-conversion double-buy not blocked
- **BUG-3** (MEDIUM): post-conversion sell window skipped when converter is already president
- **BUG-4** (MEDIUM): `can_sell?` blocks all regional sales

These are clearly described and rule-cited; they should move to the top of the next implementation session. They're more impactful than (e.g.) finishing OE9-OE11 tile orientations.

### 14. `WA-1` (national revenue) is gated on city revenues

Multiple docs note that all city revenues are `revenue:0` placeholder, so route revenue is £0 in play. This is rated `[HIGH PRIORITY]` in `18OEstatus.md` §2b but is not reflected in `CLAUDE.md`'s "Next Major Milestones" list (which mentions it as #1, but the milestone description is vague). Make this milestone more concrete — list the input sources (physical map photo? rulebook table?) and a target hex count.

### 15. Test coverage = 0

Listed in every status doc. Fix #11 above.

---

## Suggested order of attack

A reasonable two-week sprint:

1. **Day 1** — kill `MD/CLAUDE.md`, kill `Readme.MD`, point root `CLAUDE.md` at `status.md` (#2, #3, #6).
2. **Day 1** — rewrite `bugs.md` into curated form (#4).
3. **Day 2** — fix BUG-1 and BUG-2 in `buy_sell_par_shares.rb` (#13).
4. **Day 2** — add the smoke spec + pre-commit hook (#11).
5. **Day 3** — collapse `openpoints.md` / `done.md` / `working.md` into `status.md` (#1). This is the biggest doc change. Diff carefully.
6. **Day 4** — write `MD/commands.md` and `MD/decisions.md` (#8, #9).
7. **Week 2** — fill in city revenues to unblock WA-1 (#14) and the OE bonus mechanic.

---

## Files to delete

- `MD/CLAUDE.md` (duplicate)
- `MD/Readme.MD` (empty)
- `MD/working.md` (subsumed by `18OEstatus.md`)
- `MD/done.md` (subsumed by `18OEstatus.md`)
- `MD/openpoints.md` (subsumed by `18OEstatus.md`; or kept as the stripped pending-only view if you really want the workflow.md split)

## Files to rename

- `MD/18OEstatus.md` → `MD/status.md` (matches `workflow.md` convention)

## Files to rewrite

- `MD/bugs.md` (transcript → curated)
- `MD/dev_guide.md` (clarify scope vs `ENGINE_MECHANICS.md`, delete §6)
- `CLAUDE.md` root (drop hand-maintained status; point at `status.md`)

## Files to add

- `MD/commands.md` (or a Makefile)
- `MD/decisions.md`
- `MD/coding_guidelines.md` (move from `coding_guidelines.txt`)
- `spec/games/g_18_oe/smoke_spec.rb`
