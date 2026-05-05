# 18OE — Project Context

This file is the single source of project orientation for Claude (and humans). Read it at the start of every session, then read `MD/status.md` for current implementation state.

## Project Overview

This repo contains the **18xx** engine (a Ruby/Sinatra web app) with an in-progress implementation of **18OE (On the Rails of the Orient Express)**, an 18xx-style train game set on a map of 19th-century Europe.

- **Engine source**: `18xx/` — the main application codebase
- **Rules PDFs**: `rules/18OE_Rulebook_v_1.0.pdf` and `rules/18OE_Playbook_v_1.0.pdf`
- **Extracted rule text**: `rules/18OE_Rulebook_v_1.0.txt` and `rules/18OE_Playbook_v_1.0.txt`
- **Focus on 18OE full game — no changes to 18OEUKFR**

## Coding Guidelines

Best practices are in `coding_guidelines.txt` in the main directory (`~/18xx/`). Highlights:

- Keep a 130-character line limit for all changes in `.rb` files.
- Tests in `18xx/spec/` show how engine methods are actually used — read them when wiring a new mechanic.
- `lib/engine/action/*` describes the allowed player actions.
- Check other `g_18_*` games for similar functionality before implementing new features. `MD/dev_guide.md` lists the most useful comparator games.

---

## Key File Locations

| What | Path |
|---|---|
| Base game | `18xx/lib/engine/game/g_18_oe/game.rb` |
| Base game entities | `18xx/lib/engine/game/g_18_oe/entities.rb` |
| Base game meta | `18xx/lib/engine/game/g_18_oe/meta.rb` |
| Base game stub | `18xx/lib/engine/game/g_18_oe.rb` |
| Step classes | `18xx/lib/engine/game/g_18_oe/step/*.rb` |
| Operating round | `18xx/lib/engine/game/g_18_oe/round/operating.rb` |
| Rules PDFs + TXT | `rules/` |
| Implementation status | `MD/status.md` |
| Open bugs | `MD/bugs.md` |
| Map requirements | `MD/mapquest.md` |
| Engine mechanics ref | `MD/ENGINE_MECHANICS.md` |
| Abilities reference | `MD/ABILITIES_REFERENCE.md` |
| Architecture decisions | `MD/decisions.md` |
| Common commands | `MD/commands.md` |
| Git/docs setup | `MD/git.md` |

---

## Reference Documents in MD/

The `MD/` directory contains enhanced project documentation. Consult these before implementing mechanics.

### Physical Setup

```
/home/witzman/
    18xx/                    ← project root (not a git repo)
        18xx/                ← main git repo (current branch: varies)
        MD  →  symlink       ← points to /home/witzman/18xx-docs/MD/
        CLAUDE.md  →  symlink ← points to /home/witzman/18xx-docs/MD/CLAUDE.md
    18xx-docs/               ← git worktree, locked to Documentation branch
```

`MD/` is a symlink into the `Documentation`-branch worktree. It is always accessible regardless of which branch `18xx/` is on, and is invisible to git on all other branches.

**Never edit or commit MD/ or CLAUDE.md from `~/18xx/18xx/`.** To commit documentation changes:

```bash
cd ~/18xx-docs
git add MD/filename.md
git commit -m "describe change"
git push
```

See `MD/git.md` for full setup details and how to recreate the worktree/symlink if needed.

### Git Remotes

| Repo | Remote | URL |
|---|---|---|
| `~/18xx/18xx/` | `origin` | `git@github.com:Witzman/18xx.git` |
| `~/18xx/18xx/` | `upstream` | `https://github.com/tobymao/18xx.git` |
| `~/18xx-docs/` | `origin` | `git@github.com:Witzman/18xx.git` |
| `~/18xx-docs/` | `upstream` | `https://github.com/tobymao/18xx.git` |

### MD/ File Index

| File | Purpose |
|---|---|
| `MD/status.md` | **Current implementation state** — `[x]/[~]/[ ]` checkboxes for every feature. Single source of truth. Read this after `CLAUDE.md`. |
| `MD/bugs.md` | Open and resolved bug log with rule citations and fixes |
| `MD/decisions.md` | Architecture decision records — why non-obvious choices were made |
| `MD/commands.md` | Common commands: run server, lint, test, smoke check |
| `MD/openpointsread.md` | Open points + rulebook quotes (annotated companion to `status.md`) |
| `MD/ENGINE_MECHANICS.md` | Ruby engine Layer 1–4 taxonomy, event handler library, tile_lays, OR step sequence |
| `MD/ABILITIES_REFERENCE.md` | All 31 ability types, `when:` vocabulary, 18OE-specific notes |
| `MD/dev_guide.md` | Quick cheat sheet for Game::Base / Round / Step / Action API |
| `MD/mapquest.md` | Map implementation questions (revenue values, pre-printed edges) |
| `MD/workflow.md` | Doc-and-development workflow conventions |
| `MD/git.md` | Git setup — worktree/symlink structure, how to commit docs, recreate instructions |
| `MD/optimization_audit.md` | 2026-05-05 audit findings that produced this doc layout |
| `MD/CLAUDE.md` | This file — project context for Claude (symlink target) |

---

## Implementation Status

**See `MD/status.md`.** It is the source of truth and is updated against the current branch. Do not maintain a status snapshot here — it will drift.

Quick orientation:

- Game initialises and runs through Auction, Regional/Minor, and Major phases.
- Map data structurally complete; **city revenues are still placeholder 0**, so route revenue is £0 in play. This is the highest-priority blocker.
- See `MD/bugs.md` for known defects (currently includes 4 HIGH/MEDIUM bugs in `step/buy_sell_par_shares.rb`).

---

## Engine Architecture (how the Ruby engine works)

See `MD/ENGINE_MECHANICS.md` for the full reference. Summary:

**Layer 1** — Constants only (`TRAINS`, `PHASES`, `COMPANIES`, `CORPORATIONS`). No Ruby methods needed. Covers: train roster, rust triggers, phase progression, standard abilities, scalar rules. 18OE's train/phase/stock constants are Layer 1.

**Layer 2** — Named `Game::Base` method overrides. Predictable template pattern. Covers: `tile_lays`, `revenue_for`, `must_buy_train?`, `upgrades_to?`, `check_distance`, `operating_order`, `next_round!`, event handlers. 18OE's track rights, national revenue, OE bonus are Layer 2.

**Layer 3** — New custom step or round Ruby files. Covers: waterfall auction, minor acquisition/consolidation, national formation, emergency buy. 18OE's Consolidation round and ConvertToNational step are Layer 3.

**Layer 4** — Structural engine divergence. **18OE has no Layer 4 mechanics.**

---

## Game Rules Summary

### Company Types

| Type | Certs | Par Values | Float Condition |
|---|---|---|---|
| Minor | 1 (100%) | £120 fixed | Selected in auction; floated in Regional/Minor Phase |
| Regional | 3 (50%+25%+25%) | £60/65/70/75/80/90 | Pay 2× par to treasury |
| Major | 9 (20%+8×10%) | £75/80/90/100/110/120 | Expand from floated regional |
| National | 9 (20%+8×10%) | Inherits major | Forms at Phase 4/6/8 start |

### Game Phases (Railroad)

1. **Auction** — buy privates, minors, concessions
2. **Concession** (Train Phase 1) — 10 float actions in numbered order *(deferred)*
3. **Regional/Minor** — until 18 regionals + all 12 minors floated; 6 regionals removed
4. **Major** — secondary shares available; majors can float; level-3 trains available
5. **Consolidation** — first SR after Phase 5; remaining minors/regionals merge or abandon

### Train Phases & Rusting

| Level | Type | Qty | Face Value | Rusts At |
|---|---|---|---|---|
| 2 | 2+2 / — | 30 | £100 | Phase 4 |
| 3 | 3+3 / 3 | 20 | £225 / £200 | Phase 6 |
| 4 | 4+4 / 4 | 10 | £350 / £300 | Phase 8 |
| 5 | 5+5 / 5 | 8 | £475 / £400 | — |
| 6 | 6+6 / 6 | 6 | £600 / £525 | — |
| 7 | 7+7 / 4D | 14 | £750 / £850 | — |
| 8 | 8+8 / 5D | 8 | £900 / £1000 | — |

Level 8 becomes available after the 4th Level 7 purchase (not at a fixed phase).

### Train Limits by Phase

| Phase | Minor/Regional | Major | National |
|---|---|---|---|
| 1–3 | 2 | 4 | — |
| 4 | 1 | 3 | 4 |
| 5–6 | — (must merge) | 2 | 3 |
| 7–8 | — | 3 | 4 |

### Stock Market Movement

- **RIGHT**: dividend ≥ share value (also +3 RIGHT on first OE run)
- **LEFT**: zero dividend paid
- **UP**: all shares in players' hands at end of SR
- **DOWN**: each share sold
- **No move**: dividend > 0 but < share value; or at £550

### Operating Round (per company)

1. Lay track (tile pts: minor/regional=3, major=6, national=9; nationals pay no terrain costs)
2. Place token (one per OR; regionals/minors restricted to home zone)
3. Run trains & calculate revenue
4. Pay/split/hold (nationals must pay ALL as dividends)
5. Transfer tokens (majors only — between same player's majors)
6. Buy trains
7. Buy or sell shares (majors only)

### Track Rights Zones

| Zone Code | Zone Name | Home Token Cost | Terrain Discount |
|---|---|---|---|
| UK | United Kingdom | £40 | None |
| PHS | Prussia/Holland/Switzerland | £40 | None |
| FR | France/Belgium | £20 | None |
| AH | Austria-Hungary | £20 | None |
| IT | Italy | £10 | 20% |
| SP | Spain/Portugal | £10 | 20% |
| RU | Russia | £10 | 20% |
| SC | Scandinavia | £10 | 20% |

### Orient Express

- Majors only; route must include Constantinople + one of Paris/London/Berlin/Madrid/Sankt-Peterburg; must include some land track
- Constantinople is on-map pre-printed yellow at **AA82** (eastern map terminus)
- First run bonus: £30 (Phase 2–4), £60 (Phase 5–6), £100 (Phase 7–8) + RIGHT×3
- Trains level ≤4 can be combined (combined level = sum); level 5+ cannot combine

### National Revenue (unique)

Nationals have virtual tokens in every city/town in their home zone:

1. Linked cities/towns in zone → counted at face value (D trains double)
2. Remaining capacity → filled at £60/city or £10/town (no linkage required)

Implementation: `Graph.new(home_as_token: true, no_blocking: true)` — see `MD/ENGINE_MECHANICS.md §7`.

### Cross-Water Costs

- Track: Ferry = +£5 × distance; Sea = +£10 × number of sea zones
- Tokens: Ferry = +£20 × distance; Sea = +£40 × number of sea zones
- 6 sea zones: North Sea, Baltic, Western Mediterranean, Adriatic, Aegean, Black Sea

---

## Development Notes

- The engine follows the `18xx` Rails/Sinatra pattern; see `18xx/DEVELOPMENT.md`
- Game implementations live in `18xx/lib/engine/game/g_<name>/`
- Variants extend the base game via inheritance (see `g_18_oe_uk_fr/game.rb`)
- `G18OEUKFR::Entities` fully overrides `COMPANIES` and `CORPORATIONS` for the UK-FR variant; the base game `G18OE::Entities` is not affected by UK-FR changes
- Tests live in `18xx/spec/`; 18OE currently has none — see `MD/commands.md` for the smoke-spec command if/when one is added.

### Next Major Milestones (in priority order)

For the full backlog, see `MD/status.md`. Headline targets:

1. **Map revenue data** — fill in starting revenues for all named cities; confirm Constantinople / London / Lille / Dublin / Le Havre / Marseille / Bordeaux path edges. Blocks WA-1 (national revenue verification) and the OE bonus mechanic.
2. **Fix `buy_sell_par_shares.rb` bugs** — see `MD/bugs.md` BUG-001 to BUG-004 (two HIGH-severity, rule-cited).
3. **Orient Express mechanic** — route detection, bonus, RIGHT×3 stock move (`status.md` §8e).
4. **Consolidation phase** — implement merge/abandon actions in `Step::Consolidate` (`status.md` §13).
5. **Smoke spec + pre-commit hook** — first test for 18OE; high leverage for the other milestones.
