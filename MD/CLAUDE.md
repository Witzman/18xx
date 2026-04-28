# 18OE — Claude Code Project Context

## Project Overview

This repo contains the **18xx** engine (a Ruby/Sinatra web app) with an in-progress
implementation of **18OE (On the Rails of the Orient Express)**, an 18xx-style train
game set on a map of 19th-century Europe.

- **Engine source**: `18xx/` — the main application codebase
- **Rules PDFs**: `rules/18OE_Rulebook_v_1.0.pdf` and `rules/18OE_Playbook_v_1.0.pdf`
- **Extracted rule text**: `rules/18OE_Rulebook_v_1.0.txt` and `rules/18OE_Playbook_v_1.0.txt`
- **Focus on 18OE full game — no changes to 18OEUKFR**

## Coding Guidelines

There are some tests in the `18xx/spec/` directory that demonstrate how methods are actually used. 
`lib/engine/action/*` describes the allowed player actions.
`MD/dev_guide.md` Cheat Sheet for Core Architecture and Game Extensions
Check other games for similar functionalitly before implementing new feature

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
| Open points list | `MD/openpoints.md` |
| Implemented mechanics | `MD/working.md` |
| Engine mechanics ref | `MD/ENGINE_MECHANICS.md` |
| Abilities reference | `MD/ABILITIES_REFERENCE.md` |

---

## Reference Documents in MD/

| File | Purpose |
|---|---|
| `MD/working.md` | What IS implemented — mechanics described from rules perspective |
| `MD/openpoints.md` | What is NOT done — enhanced with engine layer annotations |
| `MD/mapquest.md` | Map implementation questions — converted from mapquest.txt |
| `MD/ENGINE_MECHANICS.md` | Ruby engine Layer 1–4 taxonomy, event library, tile_lays, OR steps |
| `MD/ABILITIES_REFERENCE.md` | All 31 ability types, `when:` vocabulary, 18OE-specific notes |
| `MD/CLAUDE.md` | This file |

---


---

## Engine Architecture (how the Ruby engine works)

See `MD/ENGINE_MECHANICS.md` for the full reference. Summary:

**Layer 1** — Constants only (`TRAINS`, `PHASES`, `COMPANIES`, `CORPORATIONS`). No Ruby methods.
Covers: train roster, rust triggers, phase progression, standard abilities, scalar rules.
18OE's train/phase/stock constants are Layer 1.

**Layer 2** — Named `Game::Base` method overrides. Predictable template pattern.
Covers: `tile_lays`, `revenue_for`, `must_buy_train?`, `upgrades_to?`, `check_distance`,
`operating_order`, `next_round!`, event handlers.
18OE's track rights, national revenue, OE bonus are Layer 2.

**Layer 3** — New custom step or round Ruby files.
Covers: waterfall auction, minor acquisition/consolidation, national formation, emergency buy.
18OE's Consolidation round and ConvertToNational step are Layer 3.

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

Level 8 available after 4th Level 7 purchase. Train limits by phase in `MD/openpoints.md §3`.

### Stock Market Movement

- **RIGHT**: dividend ≥ share value (+3 RIGHT on first OE run — not yet implemented)
- **LEFT**: zero dividend
- **UP**: all player-held shares at SR end (majors/nationals only)
- **DOWN**: each share sold
- **No move**: dividend > 0 but < share value; or at £550

### Operating Round (per company)

1. Lay track (tile pts: minor/regional=3, major=6, national=9; nationals pay no terrain costs)
2. Place token (one per OR; regionals/minors restricted to home zone)
3. Run trains and calculate revenue
4. Pay/split/hold (nationals must pay ALL as dividends)
5. Transfer tokens (majors only — between same player's majors) *(not implemented)*
6. Buy trains
7. Buy or sell shares (majors only)

---

## Development Notes

- The engine follows the `18xx` Rails/Sinatra pattern; see `18xx/DEVELOPMENT.md`
- Game implementations live in `18xx/lib/engine/game/g_<name>/`
- Variants extend the base game via inheritance (see `g_18_oe_uk_fr/game.rb`)
- `G18OEUKFR::Entities` fully overrides `COMPANIES` and `CORPORATIONS` for the UK-FR variant;
  the base game `G18OE::Entities` is not affected
- Tests live in `18xx/spec/`; 18OE currently has none
