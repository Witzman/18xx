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

Best practices are in `coding_guidelines.txt` in the main directory.

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
| Open points list | `openpoints.md` (root) and `MD/openpoints.md` (enhanced) |
| Full map requirements | `mapquest.txt` (root) and `MD/mapquest.md` (enhanced) |
| Engine mechanics ref | `MD/ENGINE_MECHANICS.md` |
| Abilities reference | `MD/ABILITIES_REFERENCE.md` |

---

## Reference Documents in MD/

The `MD/` directory contains enhanced project documentation. Consult these before
implementing mechanics:

| File | Purpose |
|---|---|
| `MD/ENGINE_MECHANICS.md` | Ruby engine Layer 1–4 taxonomy, event handler library, tile_lays, OR step sequence |
| `MD/ABILITIES_REFERENCE.md` | All 31 ability types, `when:` vocabulary, 18OE-specific notes |
| `MD/openpoints.md` | Enhanced open points tracker with engine layer annotations |
| `MD/mapquest.md` | Enhanced map implementation questions |
| `MD/CLAUDE.md` | This file |

---

## Implementation Status: ~55–60% Complete (Pre-Alpha)

- Full base game (`g_18_oe`) starts cleanly
- Phase 2, all 36 corporations (12 minors + 24 regionals) initialise without errors
- Waterfall auction working (`step/waterfall_auction.rb`)
- Map implemented — not complete, see `MD/mapquest.md`

### What Is Implemented

- Three-tier company hierarchy: minors → regionals → majors (conversion mechanics in place)
- **Player count**: PLAYER_RANGE [2, 7]; STARTING_CASH uses £5,400/n formula (standard)
  for 3–7 players; £2,600 for 2-player (without-concessions formula per Playbook §5.4)
- **Base game map** — `g_18_oe/map.rb` created and loadable:
  - Full grid coverage: 651 blue hexes, all 19 red off-board hexes, all land hexes
  - Terrain costs: UK/FR/Spain/Portugal/Scandinavia/Alps/Italy/Adriatic/Carpathians/
    Balkans/Caucasus/rivers all implemented
  - LOCATION_NAMES: 255 entries
  - Pre-printed yellows: Liverpool J25, Manchester J27, Athinai AE72 in yellow section
  - Constantinople AA82: white section, two city slots, revenue 20/slot placeholder —
    path edges still needed
  - SEA_ZONES: 19 named zones with hex lists complete
- **All 8 track rights zones** fully defined — manual override for playtesting active
- **Full train set** — 7 levels (2+2 through 8+8/5D) with correct quantities and rusting
- `setup` derives `@minor_available_regions` dynamically from actual regionals
- `hex_within_national_region?` nil-guarded
- Waterfall auction system (`step/waterfall_auction.rb`)
- Stock market with tiered par values (blue for regionals, red for majors); LEFT on zero dividend
- 8 game phases with train limits
- Track points system (1–4 pts by color, metropolis = 4)
- Custom OE tile definitions (OE1–OE8, OE12–OE18, OE23–OE44; OE9–11/OE20–22 commented out)
- 7 step classes: `HomeToken`, `BuySellParShares`, `Track`, `Token`, `Dividend`,
  `BuyTrain` (partial), `WaterfallAuction`
- `NATIONAL_REGION_HEXES` all 8 zones complete; `NATIONAL_REGION_HEXES_COMPLETE = true`
- Consolidation round scaffold (`round/operating.rb` + `step/consolidate.rb`)

### What Is Missing (see `MD/openpoints.md` for detail)

- **Map detail** — city revenues all placeholder 0; Constantinople/London/several other cities
  missing pre-printed path edges; off-board revenues best-guess (need verification)
- **BuyTrain step** — reserved 2+2 obligation buggy (see §3.1); no forced purchase or
  insolvency logic
- **Orient Express mechanic** — bonus revenue + RIGHT×3 stock move not implemented
- **Pullman cars** — not implemented
- **Minor special abilities** — descriptions filled in, zero functional implementation
- **Private special abilities** — descriptions filled in, zero functional implementation
- **National formation** — data structures complete; `convert_to_national`,
  `national_revenue`, `trigger_nationals_formation!` methods not yet written
- **Stock market UP movement** — `sold_out_increase?` wired but `move_up` not tested
- **Consolidation phase** — scaffold only; merge/abandon actions not implemented
- **Concession Railroad Phase** — explicitly deferred (§15)
- **Token transfer between majors** — not implemented
- **Tests** — zero test coverage for 18OE

---

## Engine Architecture (how the Ruby engine works)

See `MD/ENGINE_MECHANICS.md` for the full reference. Summary:

**Layer 1** — Constants only (`TRAINS`, `PHASES`, `COMPANIES`, `CORPORATIONS`).
No Ruby methods needed. Covers: train roster, rust triggers, phase progression,
standard abilities, scalar rules. 18OE's train/phase/stock constants are Layer 1.

**Layer 2** — Named `Game::Base` method overrides. Predictable template pattern.
Covers: `tile_lays`, `revenue_for`, `must_buy_train?`, `upgrades_to?`,
`check_distance`, `operating_order`, `next_round!`, event handlers.
18OE's track rights, national revenue, OE bonus are Layer 2.

**Layer 3** — New custom step or round Ruby files. Covers: waterfall auction,
minor acquisition/consolidation, national formation, emergency buy.
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

- Majors only; route must include Constantinople + one of Paris/London/Berlin/Madrid/
  Sankt-Peterburg; must include some land track
- Constantinople is on-map pre-printed yellow at **AA82** (eastern map terminus)
- First run bonus: £30 (Phase 2–4), £60 (Phase 5–6), £100 (Phase 7–8) + RIGHT×3
- Trains level ≤4 can be combined (combined level = sum); level 5+ cannot combine

### National Revenue (unique)

Nationals have virtual tokens in every city/town in their home zone:
1. Linked cities/towns in zone → counted at face value (D trains double)
2. Remaining capacity → filled at £60/city or £10/town (no linkage required)

Implementation: `Graph.new(home_as_token: true, no_blocking: true)` — see
`MD/ENGINE_MECHANICS.md §7`.

### Cross-Water Costs

- Track: Ferry = +£5 × distance; Sea = +£10 × number of sea zones
- Tokens: Ferry = +£20 × distance; Sea = +£40 × number of sea zones
- 6 sea zones: North Sea, Baltic, Western Mediterranean, Adriatic, Aegean, Black Sea

---

## Development Notes

- The engine follows the `18xx` Rails/Sinatra pattern; see `18xx/DEVELOPMENT.md`
- Game implementations live in `18xx/lib/engine/game/g_<name>/`
- Variants extend the base game via inheritance (see `g_18_oe_uk_fr/game.rb`)
- `G18OEUKFR::Entities` fully overrides `COMPANIES` and `CORPORATIONS` for the UK-FR
  variant; the base game `G18OE::Entities` is not affected by UK-FR changes
- Tests live in `18xx/spec/`; 18OE currently has none

### Next Major Milestones (in priority order)

1. **Map revenue data** — fill in starting revenues for all named cities; confirm
   Constantinople/London/Lille/Dublin/Le Havre/Marseille/Bordeaux path edges
2. **BuyTrain step bugs** — fix buyable_trains checks (§3.1 in openpoints.md)
3. **National formation** — implement `convert_to_national`, `national_revenue`,
   `trigger_nationals_formation!`
4. **Orient Express mechanic** — route detection, bonus, RIGHT×3 stock move
5. **Consolidation phase** — merge/abandon actions in Step::Consolidate
