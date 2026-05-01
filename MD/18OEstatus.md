# 18OE — Implementation Status

Combined status tracker: implemented items (`[x]`), partially done (`[~]`), and open
points (`[ ]`). Based on `18oe_testgame` branch (checked 2026-05-01) against rulebook v1.0.

**5 open upstream PRs** — see §19 for the table. These are feature slices submitted to
tobymao/18xx; `18oe_testgame` is ahead of all of them.

**Engine layer annotations** (see `MD/ENGINE_MECHANICS.md` for full explanation):
- **L1** = Layer 1: pure constants, no custom Ruby methods needed
- **L2** = Layer 2: named `Game::Base` method override
- **L3** = Layer 3: new step or round Ruby class required
- **L4** = Layer 4: structural engine divergence (none in 18OE)

---

## 1. Game Setup

Player count, bank, certificate limits, company structure, and capitalisation rules
are all fully implemented.

- [x] Player range 2–7 supported **[L1]**
- [x] Starting cash: £5,400 ÷ number of players (rounded to nearest £5) for 3–7 players;
  £2,600 flat for 2-player (the without-concessions formula from Playbook §5.4) **[L1]**
- [x] Bank size: £54,000 **[L1]**
- [x] Certificate limits defined for all player counts: 2 = unlimited; 3 = 48; 4 = 36;
  5 = 29; 6 = 24; 7 = 20 **[L1]**
- [x] Three-tier company hierarchy — minor (1 cert, 100%) → regional (3 certs,
  50%+25%+25%) → major (9 certs, 20%+8×10%) → national (9 certs, inherits major) **[L1]**
- [x] Incremental capitalisation — a company's treasury grows as shares are sold, not
  as a lump sum at float **[L1]**
- [x] Float condition: a regional floats when its president pays 2× par into treasury;
  a major floats by converting from a floated regional **[L2]**
- [x] Regionals cannot be dumped — blocked from sale to the bank pool in the same turn
  they are bought **[L2]**

---

## 2. Base Game Entities + Map

All company definitions are complete. The map loads and is fully playable for track
laying, though city revenues remain placeholder and port and sea-zone logic is not yet
functional.

### 2a. Company Definitions

- [x] **2.1** All 24 regional corporations defined — home city coordinates, track rights
  zone, correct cert split (50%+25%+25%), par range £60–£90 **[L1]**
- [x] **2.2** All 12 minor corporations defined — type `:minor`, single 100% certificate,
  fixed par £120, rulebook ability description text **[L1]**
- [x] **2.3** All 10 private companies defined — face values, revenues, rulebook
  description text for each ability **[L1]**
- [x] **2.4** All 12 minor auction cards defined — buying the card in the auction gives
  the player the right to float the corresponding minor in the Regional/Minor Phase **[L1]**
- [x] **2.5** All 10 concession cards (CON1–CON10) defined as entities *(Concession Phase
  itself is deferred — see §5)* **[L1]**
- [~] **2.6** Logo artwork — charter background `color:` now defined for all 12 minors
  (distinct colours: silver, maroon, teal, white, navy, gray, olive, etc.). Logo image
  files (`.svg`) still missing for 8 minors **[non-code]**:
  - Still need image logos: A (silver), B (maroon), D (white), E (navy), F (teal),
    G (white), J (gray), L (olive)
  - Regionals still needing logos (17): BHB, POB, KSS, KBS, SB; MAV, SFAI, SFR; CHN;
    MZA, RCP; MSP, MKV, LRZD; WW, DSJ, BJV
  - Already have real logos: LNWR, GWR, GSWR (UK); PLM, MIDI, OU, BEL (FR); minors C/H/K/M

### 2b. Map

- [x] Full grid — 651 blue sea/blank hexes covering the whole map area **[L1]**
- [x] All 19 red off-board hexes implemented with best-guess revenues (pending verification
  against physical map) **[L1]**
- [x] All terrain costs applied: mountains/Alps, rough terrain (Carpathians/Balkans/
  Caucasus), water crossings (UK, Ireland, Adriatic, rivers) **[L1]**
- [x] 255 location names (`LOCATION_NAMES`) — every named city, town, and off-board
  label from the rulebook map **[L1]**
- [x] All 255 named locations carry a station slot with placeholder revenue 0 — sufficient
  for game initialisation and track laying **[L1]**
- [x] Pre-printed yellow tiles: Liverpool J25, Manchester J27, Athinai AE72, Amsterdam L37,
  Kobenhavn I50 placed in yellow section; I48 (Kattegat crossing) pre-printed yellow
  track **[L1]**
- [x] All on-board city revenues set to `revenue:0` — ports will be the only source of
  pre-printed revenue once implemented **[L1]**
- [x] Pre-printed ferry paths on white cities (forced upgrade edges): N31 Lille (→1),
  M28 London (←5), AA82 Constantinople (→2), I20 Dublin (→4), O28 Le Havre (→1),
  X33 Marseille (→5) **[L1]**
- [x] All 8 national zone hex lists embedded (`NATIONAL_REGION_HEXES`): UK, SC, FR, PHS,
  AH, IT, SP, RU — used for token zone restrictions and national revenue **[L1]**
- [x] Two stale `NATIONAL_REGION_HEXES` entries removed: `A40` from `SC` (now a blue sea
  hex) and `E88` from `RU` (removed from map entirely) **[L1]**
- [x] `SEA_ZONES` — 19 named sea zones each with their hex lists defined, ready for
  cross-water cost calculations **[L1]**
- [~] Ferry sea hexes — partial (more routes outstanding): N29 (4↔2), G22 (0↔4),
  N25 (0↔3), I22 (1↔5+1↔4), I24 (1↔5+1↔4), AE12 (3↔0), AF13 (2↔1),
  AB21 (2↔4), AB23 (1↔4), AB25 (1↔4) **[L1]**
- [~] Public port icons (`icon=image:port,sticky:1`) added to ~40 hexes in PR #12558
  (`18oe_ports`) — 6 cities, 9 towns, 3 double towns extracted into groups; 14 cities
  + 6 towns + 10 red/yellow/blue hexes updated in-place. **Not yet merged into
  `18oe_testgame`.** Private ports remain unimplemented. **[L1]**
- [~] Lille↔London ferry (N31→N29→M28): open for playtesting — forced upgrade edges on
  both cities mean tiles connect correctly; all other ferry routes blocked pending
  engine override (see openpoints.md §2.7) **[L2 outstanding]**
- [ ] City revenues: all named locations have placeholder `revenue:0` — actual starting
  revenues needed from physical map **[HIGH PRIORITY]**
- [ ] Sea zone borders, ferry distance numbers not encoded **[L1]**
- [ ] Ferry route engine override — tile placement validator rejects exits toward blue hexes
  by default; needs a `game.rb` override to whitelist exits toward blue hexes that carry a
  matching pre-printed path **[L2]**

---

## 3. Track Rights Zones

All 8 zones are fully defined. Zone fees, token restrictions, chit availability, and
terrain discounts are enforced.

- [x] All 8 track rights zones defined (UK, PHS, FR, AH, IT, SP, RU, SC) with correct
  home token costs: UK/PHS £40; FR/AH £20; IT/SP/RU/SC £10 **[L1]**
- [x] Zone fee paid automatically when a regional par price is set — deducted from the
  regional's treasury at the moment of parring **[L2]**
- [x] Token placement for regionals and minors restricted to their own track rights zone;
  placing outside it raises an error **[L2]**
- [x] Minor zone assigned at home-token placement and used for all subsequent zone checks
  throughout the game **[L2]**
- [x] Minor home-token placement restricted to zones with available chit slots; selecting
  a minor from UK, PHS, or FR counts against the combined 4-selection cap for those three
  asterisked zones — once the cap is reached, remaining UK/PHS/FR chits are removed **[L3]**
- [x] `@minor_available_regions` built dynamically from the actual regional corporation
  list at game start — stays correct if the corporation list changes **[L1/L2]**
- [x] Home-token location list hides hexes in exhausted zones — `home_token_locations`
  filters out `CITY_NATIONAL_ZONE`-overridden hexes whose zone has no remaining
  chits **[L2]**
- [x] Terrain cost discounts for IT/SP/RU/SC zones — `tile_cost_with_discount` reads
  `track_rights_for(corp)` and applies 20% discount; duplicate rights have no cumulative
  effect **[L2]**

---

## 4. Auction Phase

The waterfall auction and minor floatation mechanism are fully implemented.

- [x] Waterfall auction with tiered rows — only the cheapest unpurchased row may be bought
  outright; companies in higher rows require a competitive bid **[L3]**
- [x] Buying a minor's auction card gives the right to float that minor later in the
  Regional/Minor Phase; the minor's treasury receives the fixed £120 par (capped at the
  auction price, maximum £180) at the moment the card is purchased **[L3]**

---

## 5. Concession Railroad Phase (DEFERRED — Out of Scope)

The 10 concession cards are defined as entities (§2.5). The Concession Phase itself
is explicitly deferred for this development pass. The 2-player without-concessions
starting cash (£2,600) is already in `STARTING_CASH`.

**What it involves:** After the Auction Phase ends, 10 "Concession Railroad" float
actions occur in numbered order. Each concession holder pays 2× par to float their
regional or major.

**Reason for deferring:** Requires a distinct round type with queue management; the
complexity is not justified until other core mechanics are playable. Current
implementation skips from Auction directly to Regional/Minor Phase.

- [ ] **5.1** Define Concession round type with ordered float actions (CON1–CON10) **[L3]**
- [ ] **5.2** Wire concession cards to specific regional/major home tokens and par values **[L1]**
- [ ] **5.3** Float obligation: concession holder pays 2× par; obligation transfers if
  holder cannot pay **[L3]**
- [ ] **5.4** Round sequencing: Auction → Concession → Regional/Minor Phase **[L2]**
- [ ] **5.5** 2-player without-concessions variant: skip concession phase (starting cash
  already correct) **[L2]**

---

## 6. Stock Market & Stock Round

The full stock market grid, par colour bands, all four price-movement directions, and
per-entity dividend type restrictions are implemented. The stock round structure (sell/buy
order, conversions, share issuance, post-conversion sell window) is complete.

### 6a. Stock Market Grid & Par Values

- [x] Stock market grid — 8 rows × 17 columns with correct prices; highest cell (£550)
  is the no-movement ceiling **[L1]**
- [x] Par colour bands — blue cells mark regional par values (£60–£90); red cells mark
  major par values (£75–£120) **[L1]**

### 6b. Share Price Movement

- [x] **LEFT** — a company that pays zero dividend moves its share price one step left
  at the end of that OR; applies to majors and nationals only (minors/regionals do not
  move) **[L2]**
- [x] **No movement** — a company that pays a dividend greater than zero but below its
  current share price does not move; no movement at the £550 ceiling **[L2]**
- [x] **RIGHT** — a company that pays a dividend at or above its current share price
  moves one step right; applies to majors and nationals only **[L2]**
- [x] **UP** — at the end of each SR, a company whose shares are entirely in players'
  hands (none in bank pool or treasury) moves one step up; restricted to majors and
  nationals — regionals do not trigger UP movement **[L2]**
- [x] Minors and regionals pay dividends but do not trigger share price movement —
  they are not publicly traded at that stage **[L2]**
- [ ] **+3 RIGHT** — on the first Orient Express run by a major, the share price moves
  three steps right in addition to the normal dividend movement **[L2]** *(depends on §8e)*

### 6c. Stock Round Structure

- [x] Sell-then-buy order within each player's turn **[L1]**
- [x] Home token placement available during the Stock Round — this is how minors float
  (player places the minor's home token, triggering float) **[L3]**
- [x] Regional → major conversion available from the Major Phase onwards (once 18 regionals
  and all 12 minors have floated and the 6 unfloated regionals are closed) **[L2]**
- [x] Share issuance for majors — a major may sell treasury shares into the bank pool **[L2]**
- [x] §9.3 post-conversion sell window — after conversion completes but before the
  mandatory president share buy, the active player may sell shares of other RRs they
  own; they may not sell shares of the newly floated major **[L2]**
- [x] Minor SR merge action — during Major Phase a player may merge one of their floated
  minors into a floated major or national (one merger per major/national per SR); see §12
  for full details **[L2/L3]**
- [ ] Voluntary regional removal — player may remove one of their own unfloated regionals
  during Regional/Minor Phase (max 6 total across all players); action type TBD **[L2/L3]**

### 6d. Dividend Options Per Entity Type

- [x] Minors: half-pay only (half to treasury, half to shareholders) — withheld amount
  rounded down to share-exact multiple **[L2]**
- [x] Nationals: full payout only — nationals must pay all revenue as dividends; withhold
  and half-pay not available **[L2]**
- [x] Majors and regionals: all three options — full payout, half pay, withhold **[L2]**

---

## 7. Train Roster & Game Phases

The full train roster and all phase transitions are implemented. Train limits per
company type are defined for every phase.

### 7a. Train Data

| Level | Local / Express | Qty | Face Value | Rusts at |
|---|---|---|---|---|
| 2 | 2+2 / — | 30 | £100 | Level 4 |
| 3 | 3+3 / 3 | 20 | £225 / £200 | Level 6 |
| 4 | 4+4 / 4 | 10 | £350 / £300 | Level 8 |
| 5 | 5+5 / 5 | 8 | £475 / £400 | — |
| 6 | 6+6 / 6 | 6 | £600 / £525 | — |
| 7 | 7+7 / 4D | 14 | £750 / £850 | — |
| 8 | 8+8 / 5D | 8 | £900 / £1,000 | — |

- [x] Full 7-level train roster with correct quantities and face values for every
  train and local variant **[L1]**
- [x] Rust triggers: 2+2 trains rust when the first Level 4 is purchased; 3-level trains
  rust when the first Level 6 is purchased; 4-level trains rust when the first Level 8
  is purchased **[L1]**
- [x] Level 8 trains unlock after the 4th Level 7 purchase — fires as a game event, not
  at a fixed phase boundary **[L1]**

### 7b. Phase Structure & Train Limits

- [x] 8 named game phases (2 through 8+8) with correct train limits per company type:
  Phases 1–3: minor/regional 2, major 4; Phase 4: minor/regional 1, major 3, national 4;
  Phases 5–6: major 2, national 3; Phases 7–8: major 3, national 4 **[L1]**
  *(Note: Phase 1 — Concession Phase — is deferred)*
- [x] Tile colour availability by phase: yellow from Phase 2; green from Phase 3; brown
  from Phase 5; gray from Phase 7 **[L1]**
- [x] Phase status flags: `train_obligation` (Phases 2–3); `can_buy_trains_from_others`
  (Phase 4 onwards); `can_merge_minors` (Phase 3 onwards) **[L1]**
- [x] Consolidation event fires when the first Level 5 train is purchased, triggering the
  Consolidation Phase at the next SR **[L1]**
- [x] National corporation type `:national` with correct train limits in each phase **[L1]**
- [x] All 8 national zone hex lists defined; `NATIONAL_REGION_HEXES_COMPLETE = true`;
  border-city zone overrides (`CITY_NATIONAL_ZONE`) defined; cities barred from minor
  home-token placement (`MINOR_EXCLUDED_HOME_CITIES`) defined **[L1]**

---

## 8. Operating Round

Operating rounds run after every stock round. Each company acts in float order (minors
and regionals first, then majors/nationals by share price). The steps within each
company's turn follow the sequence below.

### 8a. Operating Order

- [x] Companies operate in float order: minors and regionals first, in the order they
  placed their home token; then majors and nationals sorted by share price descending **[L2]**

### 8b. Track Laying

**Tile point costs:** Yellow lay = 1 pt (metropolis = 2 pt); upgrade = 2 pt
(metropolis upgrade = 4 pt). Point budgets: minors/regionals = 3 pt, majors = 6 pt,
nationals = 9 pt.

**OE custom tile implementation state:**
- OE1–OE8: yellow — ✓
- OE9–OE11: green double-towns — commented out (path edge orientations unknown)
- OE12–OE18: green special city — ✓
- OE19: **missing entirely** — tile type unknown
- OE20–OE22: brown double-towns — commented out (path edge orientations unknown)
- OE23–OE33: brown special city — ✓
- OE34–OE44: gray special city — ✓

- [x] **OE1–OE3** — yellow double-town tiles (quantities 4, 6, 2) **[L1]**
- [x] **OE4–OE8** — yellow metropolis/special-city tiles **[L1]**
- [x] **OE12–OE18** — green special-city tiles **[L1]**
- [x] **OE23–OE33** — brown special-city tiles **[L1]**
- [x] **OE34–OE44** — gray special-city tiles **[L1]**
- [x] Tile point budgets enforced: minors/regionals 3 pt, majors 6 pt, nationals 9 pt **[L2]**
- [x] Tile point costs enforced: yellow lay 1 pt; upgrade 2 pt; metropolis upgrade 4 pt **[L2]**
- [x] City tiles must use the maximum number of exits when upgraded
  (`TILE_UPGRADES_MUST_USE_MAX_EXITS`) **[L1]**
- [x] Metropolis upgrade label enforcement — correct upgrade paths verified for Amsterdam (A),
  Berlin (B), Constantinople (C), Paris (P), and Sankt-Peterburg (S) **[L2]**
- [x] Nationals pay no terrain costs when laying track **[L2]**
- [ ] **9.1** OE9–OE11: green double-town path edge orientations needed **[L1]**
- [ ] **9.2** OE20–OE22: brown double-town path edge orientations needed **[L1]**
- [ ] **9.3** OE19: tile type unknown — must be identified and defined **[L1]**
- [ ] **9.4** Verify standard tile quantities against the physical tile manifest **[L1]**
- [ ] **9.5** Audit all OE-specific tile upgrade paths against the physical manifest **[L1]**

### 8c. Token Placement

- [x] Token placement for regionals and minors restricted to their home track rights zone **[L2]**
- [x] Connectivity check enforced — a token may only be placed in a city connected to
  the company's existing network **[L2]**
- [x] Nationals cannot place station tokens — token placement step skipped for
  nationals **[L2]**

### 8d. Route & Revenue (Cross-Water)

No cross-water cost or route-restriction logic is implemented yet. Sea zones are defined
as a data constant but not used in revenue calculation.

- [ ] **10.1** Cross-water costs: Ferry = +£5 track / +£20 token × distance;
  Sea = +£10 track / +£40 token × number of sea zones **[L2]**
- [ ] **10.2** Ferry mechanics: ferry distance counts against the city limit; public ferry
  track usable by any RR; enemy tokens block access to the public port city **[L2]**
- [ ] **10.3** Port authority markers: each reduces sea zone count + ferry distance by 2;
  16 total (8 North Sea, 8 Mediterranean) **[L2/L3]**
- [ ] **10.4** Port types: public (anchor in light-blue circle, any RR) vs private (anchor
  in red circle, restricted to the token-owning RR) **[L2]**
- [ ] **10.5** Offshore port mechanics: train connects to the city regardless of intervening
  hexes **[L2]**
- [ ] **10.6** Channel passages: adjacent sea-zone indicators at Copenhagen and
  Constantinople **[L2]**
- [ ] **10.7** Local train town counting: towns beyond the city limit fill up to the train
  level; express trains skip towns entirely **[L2]**
- [ ] **10.8** Combined train runs for OE: Level ≤4 trains combine (combined level = sum);
  Level 5+, 4D, and 5D cannot combine **[L2]**

### 8e. Orient Express

No Orient Express logic is implemented yet. Prerequisite: city revenues (§2b) must be
filled in first.

- [ ] **11.1** Detect a valid OE route: must include Constantinople (AA82) plus one of
  Paris, London, Berlin, Madrid, or Sankt-Peterburg; must include some land track **[L2]**
- [ ] **11.2** First-time bonus paid by the bank to the major's treasury: £30 (Phases 2–4),
  £60 (Phases 5–6), £100 (Phases 7–8); OE marker placed on the major **[L2]**
- [ ] **11.3** Share price moves RIGHT×3 on the first OE run (in addition to the normal
  dividend movement) **[L2]** *(also listed as §6b)*
- [ ] **11.4** Train combining for OE: Level ≤4 trains combine; combined level = sum;
  city limit = combined level **[L2]**
- [ ] **11.5** Subsequent OE runs: no bonus, no extra stock movement **[L2]**
- [ ] **11.6** Mandatory OE: if the OE route is the best possible route, the president must
  run it **[L2]**
- [ ] **11.7** OE blocked for nationals — nationals may not run the Orient Express **[L2]**
- [ ] **11.8** D-train bonus does NOT apply to the OE first-time bonus **[L2]**

### 8f. Pullman Cars

No Pullman car logic is implemented for majors or minors. Nationals have an inherent
Pullman bonus built into the national revenue calculation (§11.5 below).

- [ ] **12.1** Pullman asset type — does not count against train limit; maximum 1 per
  non-national company **[L3]**
- [ ] **12.2** Revenue bonus: +£10 × the train level it is assigned to, added once per OR **[L2/L3]**
- [ ] **12.3** Purchase from Minor M: £150 face value + £15 royalty; J-minor discount
  applies to purchase price but not to royalty **[L3]**
- [ ] **12.4** Purchase from Open Market: £150, no royalty; available Phase 4 onwards **[L3]**
- [ ] **12.5** Purchase from another RR: negotiated price **[L3]**
- [ ] **12.6** Minor M free Pullman: if Minor M has not yet closed at the start of Phase 4,
  it places a free Pullman **[L2/L3]**
- [ ] **12.7** Discard order: rusted trains are discarded first; Pullman may be voluntarily
  returned to the Open Market **[L3]**
- [ ] **12.8** If a company has zero trains but still holds a Pullman, the Pullman is
  retained until the next train is acquired **[L3]**

### 8g. Train Purchase

The reserved 2+2 obligation is fully implemented. Forced purchase and insolvency
are not yet done.

- [x] **3.1** Reserved 2+2 obligation fully implemented **[L2]**:
  - Obligation tracked per entity via `@fulfilled_train_obligation` (Set) — a one-time
    flag; never re-triggers if a train rusts or is later lost
  - `must_buy_train?` uses the Set flag plus a phase status check (not a hard-coded
    phase number)
  - `buyable_trains` enforces two independent restrictions: (1) during Regional/Minor
    Phase all entities restricted to level 2 trains only; (2) during Major Phase an entity
    with an outstanding obligation is restricted to the cheapest depot train
  - `process_buy_train` snapshots phase status before calling `super` so a phase change
    during purchase cannot cause a missed fulfilment mark
- [ ] **3.2** Forced purchase — president covers shortfall; else national conversion
  (majors) or insolvency (minors/regionals) *(president contribution relies on base
  engine; national/insolvency conversion deferred)* **[L3]**
- [ ] **3.3** First-round insolvency: president's cash → treasury; company receives a
  reserved 2+2; presidential cert moves to Open Market; president receives face-value
  payment **[L3]**
- [x] **3.4** Reserved 2+2 obligation automatically waived if Phase 4 arrives before a
  company has had its first Operating Round — checked via phase status flag **[L2]**
- [x] **3.5** Depot level gating — a company may only buy the cheapest available train level
  from the depot (cannot skip levels) **[L2]**
- [x] **3.6** Purchasing a train from another railroad is permitted only from Phase 4 onwards;
  blocked in Phases 2–3 **[L2]**
- [~] **3.7** Nationals may claim unclaimed rusted trains from the depot for free, up to
  their train limit — `spend_minmax` returns `[0,0]`, `process_buy_train` fast-paths the
  free claim. Exchange/flip/upgrade of owned rusted trains deferred. **[L2/L3]**

---

## 9. Minor Special Abilities

Rulebook description text is in place for all 12 minors. No ability is functionally
active in the engine. No transfer-on-merge mechanism exists yet.

See `MD/ABILITIES_REFERENCE.md §2` for the engine ability types needed for each minor.

- [x] All 12 minor ability descriptions entered — A (Silver Banner), B (Orange Scroll),
  C (Golden Bell), D (Green Junction), E (Blue Coast), F (White Peak), G (Indigo Foundry),
  H (Great Western Steamship), J (Grey Locomotive Works), K (Vermilion Seal),
  L (Krasnaya Strela), M (CIWL) **[L1]**
- [ ] **7.1** Ability transfer mechanism — when a minor merges with a major, the minor's
  charter goes under the major's and the ability is inherited; nationals cannot inherit
  minor abilities (except stock-type) **[L3]**
- [ ] **7.2** Minor A (Silver Banner): bank pays the major an amount equal to the current
  share price of the major at the moment of merger **[L3]**
- [ ] **7.3** Minor B (Orange Scroll): all track upgrades cost only 1 tile point (does
  not apply to city, grand city, or metropolis upgrades) **[L2]**
- [ ] **7.4** Minor C (Golden Bell): the president may choose the minor's position in the
  operating order each OR **[L3]**
- [ ] **7.5** Minor D (Green Junction): place one free token in any non-metropolis,
  non-red-zone city; that token pays £20 (Phases 1–4) or £40 (Phase 5+) to treasury
  each OR; token is removed at the start of Phase 5 **[L3]**
- [ ] **7.6** Minor E (Blue Coast): 33% discount on water-crossing terrain costs; +1 tile
  point when laying in blue (water) hexes **[L2]**
- [ ] **7.7** Minor F (White Peak): 33% discount on mountain-terrain costs; +1 tile point
  when laying in green (mountain) hexes **[L2]**
- [ ] **7.8** Minor G (Indigo Foundry): +2 tile points per OR **[L2]**
- [ ] **7.9** Minor H (Great Western Steamship): reduces the number of sea zones counted
  for a route by 1 (Phases 1–6) or 2 (Phases 7–8) **[L2]**
- [ ] **7.10** Minor J (Grey Locomotive Works): 10% discount on all train purchases **[L2]**
- [ ] **7.11** Minor K (Vermilion Seal): mail contract — pays a fixed revenue to the
  company's treasury at the start of each OR **[L2]**
- [ ] **7.12** Minor L (Krasnaya Strela): the +1+1 marker adds 1 city limit and 1 town
  count to one assigned train per OR **[L3]**
- [ ] **7.13** Minor M (CIWL): holds 10 Pullman cars (see §8f) **[L3]**

---

## 10. Private Special Abilities

Rulebook description text is in place for all 10 privates. No ability is functionally
active in the engine.

See `MD/ABILITIES_REFERENCE.md §2` for the engine ability types needed for each private.

- [x] All 10 private ability descriptions entered — Wien Südbahnhof, Barclay Bevan Barclay
  & Tritton, Star Harbor Trading Co., Central Circle Transport Corp., White Cliffs Ferry,
  Hochberg Mining & Lumber, Brandt & Brandau Engineers, Swift Metropolitan Line, plus the
  two no-ability privates (Robert Stephenson and Co., Ponts et Chaussées) **[L1]**
- [ ] **8.1** Wien Südbahnhof: free station token placement during any controlled RR's
  token step **[L3]**
- [ ] **8.2** Barclay, Bevan, Barclay & Tritton: owner selects one of three abilities
  at time of use **[L3]**
- [ ] **8.3** Star Harbor Trading Co.: place a port token in any port city during a
  controlled RR's token step **[L3]**
- [ ] **8.4** Central Circle Transport Corp.: place a token as a town in any non-port
  city during a controlled RR's token step **[L3]**
- [ ] **8.5** White Cliffs Ferry: at the start of Phase 5 the owner may immediately
  place one tile at Lille (N31), enabling a ferry crossing **[L3]**
- [ ] **8.6** Hochberg Mining & Lumber: place a token on any rough-terrain hex; that
  hex may then only receive track laid by the owning RR **[L3]**
- [ ] **8.7** Brandt & Brandau, Engineers: 4 tokens usable at up to 2 per OR across
  one or two controlled RRs; each token grants one free yellow tile lay; company closes
  when the last token is used **[L3]**
- [ ] **8.8** Swift Metropolitan Line: from Phase 4 onwards, designates one controlled
  RR to keep one 2+2 train outside the normal train limit **[L3]**

---

## 11. Nationals

National formation, revenue calculation, train inheritance, and operating rules are
fully implemented. Deferred items are the minor abandon/track-rights cleanup (depends
on §12) and advanced rusted-train interactions.

- [x] **1.1** National corporation type `:national` defined in train limits for every
  phase that has nationals (Phase 4 through 8) **[L1]**
- [x] **1.2** National formation trigger — when a Phase 4/6/8 train is purchased,
  `Step::BuyTrain` detects the phase change and calls `trigger_nationals_formation!`;
  an ordered queue is built starting with the buying player then all other players who
  own at least one major, in seat order **[L2]**
- [~] **1.3** National formation steps (executed by `Step::ConvertToNational`): **[L2/L3]**
  - [x] Major's cash → bank
  - [x] All major treasury certificates → Open Market
  - [x] All major tokens removed from map
  - [ ] Merged minors abandoned *(deferred — depends on §12 `@minor_track_rights`)*
  - [ ] Track rights, OE markers, private markers removed *(deferred — same dependency)*
  - [x] National placed in share-value sort bucket alongside majors
  - [x] National inherits all trains from the forming major
- [x] **1.4** National revenue calculation (`national_revenue` in `game.rb`): **[L2]**
  - Iterates all zone hexes; linked cities/towns scored at face value, best-first up to
    train capacity
  - Remaining capacity filled at £60/city, £10/town (no linkage required)
  - D trains double linked city revenue
  - Nationals must pay ALL revenue as dividends — `dividend_types` returns `[:payout]` only
- [x] **1.5** Inherent Pullman bonus: `national_revenue` adds +£10 × level of the highest
  non-rusted train the national owns **[L2]**
- [x] **1.6** Nationals cannot place station tokens — `Step::Token#actions` returns `[]`
  for nationals **[L2]**
- [x] **1.7** Nationals pay no terrain costs when laying track **[L2]**
- [x] **1.8** Nationals inherit the forming major's trains; if that exceeds the national
  train limit, cheapest excess trains are discarded via `depot.reclaim_train` **[L2]**
- [~] **1.9** Nationals and rusted trains (§11.6.6): **[L2/L3]**
  - [x] Claim unclaimed rusted trains from depot for free, up to train limit
  - [ ] Exchange owned rusted train for any higher-level unclaimed rusted train *(deferred)*
  - [ ] Flip owned rusted train from express side to local side *(deferred)*
  - [ ] Upgrade rusted → non-rusted by purchasing from same-owner major *(deferred)*
- [x] **1.10** `NATIONAL_REGION_HEXES` all 8 zones; `NATIONAL_REGION_HEXES_COMPLETE = true`;
  `CITY_NATIONAL_ZONE` overrides; `MINOR_EXCLUDED_HOME_CITIES` defined **[L1]**
- [x] **1.11** `@minor_available_regions` derived dynamically from the actual regional
  corporation list at game start **[L1/L2]**

---

## 12. Minor Merger Rules

The full §10.5 merger action is implemented for the common cases. Structural/edge-case
items remain deferred.

### A — Track-rights chit system

- [x] `MINOR_TRACK_RIGHTS_CHITS {zone => 2}`: 8 zones × 2 chits = 16 total for 12 minors **[L1]**
- [x] `ASTERISKED_ZONES [UK, PHS, FR]`, `ASTERISKED_ZONES_CAP = 4`: when the 4th asterisked
  chit is taken, all remaining UK/PHS/FR chits are removed from the pool **[L1]**
- [x] `setup`: chit pool initialised; `region_available?`, `track_rights_cost`, `claim_region!`
  in `game.rb` **[L2]**
- [x] `HomeToken#process_place_token`: determines zone, validates availability, pays fee,
  calls `claim_region!`, records `@minor_floated_regions[minor.id] = zone` **[L3]**
- [x] `major_phase?`: gated on all minors having placed home tokens in addition to floated
  regional count **[L2]**

### B — §10.5 merger action: engine plumbing

- [x] `minor_by_id(id)` override in `game.rb` — returns corp filtered to type `:minor` so
  `Action::Merge` deserialises correctly (18OE minors live in `@corporations`) **[L2]**
- [x] `'can_merge_minors'` status added to PHASES 3–8 **[L1]**
- [x] `@minor_track_rights` hash in `setup`; `track_rights_for(corp)` returns initial zone
  plus all inherited merger zones, deduplicated **[L2]**
- [x] `round_state` in `BuySellParShares` adds `minors_merged_into: []` — reset each new
  round; tracks which majors/nationals already received a minor this SR **[L2]**

### C — §10.5 merger action: stock round UI

- [x] `'merge'` added to `actions(entity)` when conditions met **[L2]**
- [x] `mergeable_entity` → first floated minor of current player with eligible targets;
  `mergeable_entities` → all floated majors/nationals not yet merged this SR **[L2]**
- [x] `process_merge(action)`: validates ownership, calls `game.merge_minor!`, tracks the
  merged major, calls `pass!` **[L3]**

### D — `game.merge_minor!` sub-steps

- [x] Share exchange: major treasury stock → minor owner; if none, Open Market stock;
  if neither, logs and continues **[L2]**
- [x] Cash transfer: minor cash → major treasury if treasury share was given; otherwise
  → bank **[L2]**
- [x] Token transfer (majors only): minor's used tokens swapped to unused major tokens
  where available; conflicts auto-declined (player choice deferred) **[L2]**
- [x] Train transfer (majors and nationals): trains moved up to train limit; excess
  reclaimed to depot **[L2]**
- [x] Track rights transfer (majors only): minor's zone added to major's
  `@minor_track_rights`; 20% terrain discount applied via `tile_cost_with_discount` **[L2]**
- [x] Close minor: remove from operating order and floated regions; call `close_corporation` **[L2]**
- [x] Nationals: no tokens/rights/special-ability inherited; cash forfeited to bank;
  train and share transfer as above **[L2]**

### E — Deferred items

- [ ] No-stock hypothetical connection check: merge only if an unlimited-city-limit train
  could reach from minor's token to major's network (or national's zone) **[L3]**
- [ ] Player choice on token conflict and train decline (auto-handled in v1) **[L3]**
- [ ] Cross-player personal cash side payment UI **[L3]**
- [ ] Solicit-offers rule for unmergeable minors **[L3]**
- [ ] Consolidation Round forced mergers (§10.6) — hook into `Step::Consolidate` **[L3]**

---

## 13. Consolidation Phase

Triggered by the first Level 5 train purchase. The trigger and round scaffolding are in
place; the actual merge and abandon actions are not yet implemented.

- [x] Consolidation trigger — the first Level 5 purchase fires a game event; after the
  current OR set completes, the next round type is a dedicated Consolidation Round
  (fires once only via `@consolidation_done`) **[L1/L2]**
- [~] Consolidation Round exists as a named round type with a Consolidate step that
  identifies which player-owned minors and regionals must be resolved — pass only;
  merge/abandon actions not yet handled **[L3 scaffold]**
- [ ] A player cannot pass if they own unfloated minors or regionals that have not yet
  been merged or abandoned **[L2]**
- [ ] Conditional merger: major/national may make an offer to a minor or regional; if
  no offer is made the company is abandoned **[L3]**

---

## 14. Token Transfer Between Majors

Not implemented.

- [ ] During a major's Transfer Tokens step in the OR, the controlling player may transfer
  one token between two majors they control **[L2]**
- [ ] Cost: token value from paying major + token value from receiving major for same zone +
  transfer fee (Normal £20, Grand £40, Metropolis £60) **[L2]**
- [ ] Selling a token: token returns to the charter at the highest-cost open position **[L2]**

---

## 15. End Game Rules

Not implemented.

- [ ] Bank break before Level 8 unlocks: finish only the current OR, then the game ends **[L2]**
- [ ] Level 8 unlock path: remaining bank cash added to bank; finish current OR; one final SR;
  two final ORs **[L2]**
- [ ] Second of the two final ORs: each company pays the same revenue it paid in the first
  final OR — no track laying, token placement, or train purchases **[L2]**
- [ ] Win condition: player with highest total of cash + stock at share value + face-up
  private companies at face value wins **[L2]**

---

## 16. Tests

No automated tests exist for 18OE yet.

- [ ] Basic game flow test (auction → regional/minor phase → major phase)
- [ ] Train phase transition tests (rusting, limit changes, national formation trigger)
- [ ] Stock market movement tests (right/left/up/down triggers, edge cases)
- [ ] National revenue calculation test
- [ ] Orient Express bonus test (first run, subsequent runs)
- [ ] Minor ability transfer tests
- [ ] Pullman car revenue test (nationals inherent Pullman)

---

## 17. Variants

No variant-specific items are confirmed implemented. The UK-FR variant
(`g_18_oe_uk_fr`) has its own entity and map files but is out of scope for the current
development pass.

- [ ] Confirm UK-FR variant entities match rulebook (4 minors: C, H, K, M;
  7 regionals: BEL, GSWR, GWR, LNWR, MIDI, OU, PLM) **[L1]**
- [ ] UK-FR variant train rusting rules **[L1]**
- [ ] Validate UK-FR map hex definitions against the rulebook **[L1]**
- [ ] Other scenarios (medium/short) — reduced RR counts, modified OE destinations **[L1]**

---

## 18. Temporary Workarounds

Active code workarounds that bypass correct behaviour to allow playtesting. Tagged
`WA-N` in source.

### WA-1 — National revenue: linked/unlinked split not yet verified *(PENDING)*

`national_revenue` iterates zone nodes and distinguishes linked (reachable by track)
from unlinked (flat-rate). City revenues are all `0` placeholders so this cannot be
meaningfully tested. **To remove**: fill in city revenues; verify that
`Graph.new(home_as_token: true, no_blocking: true)` correctly identifies linked nodes;
run a national in a test game and confirm linked vs flat-rate split.

### WA-5 — Silent `skip!` in `ConvertToNational` *(KEEP PERMANENTLY)*

`skip!` is a no-op when the national formation queue is empty. `process_pass` uses the
queue head as `current_entity` rather than `action.entity`. This is correct behaviour
for a conditional blocker step — do not remove.

*(WA-3 and WA-4 were removed 2026-04-29 when `convert_to_national` and
`step/convert_to_national.rb` were fully implemented.)*

---

## 19. Upstream Engine Requests

### 19.1 — Province partition rendering *(PENDING)*

`assets/app/view/game/part/partitions.rb` does not handle `type:province` partitions
(needed for orange dashed national border lines inside hexes). Reviewer feedback
(2026-04-26): extend `Partitions` itself — add `:province` to the `color` case,
add `partition_dash` helper, apply `stroke-dasharray`. No game-side callback needed.

**Current workaround**: use `type:divider` (black solid line) until upstream accepts PR.

---

## 20. Outstanding Upstream Pull Requests

Open PRs against tobymao/18xx from Witzman. `18oe_testgame` is ahead of all of these.

| PR | Branch | Title | Covers |
|---|---|---|---|
| [#12542](https://github.com/tobymao/18xx/pull/12542) | `18oe_minorzones` | Minor track-rights chit system | §12A: chit pool, `claim_region!`, zone cap |
| [#12543](https://github.com/tobymao/18xx/pull/12543) | `18oe_buytrains` | Reserved 2+2 train obligation | §8g 3.1, 3.4–3.6: obligation Set, depot gating |
| [#12544](https://github.com/tobymao/18xx/pull/12544) | `18oe_fullmap` | Stock round — pre-conversion buy guard and major share redemption | §6c: `can_buy?` guard, `issuable_shares`/`redeemable_shares` |
| [#12558](https://github.com/tobymao/18xx/pull/12558) | `18oe_ports` | Mapupdate — Public ports + minor charter colors | §2a 2.6 colors; §2b port icons (~40 hexes); terrain rename |
| [#12561](https://github.com/tobymao/18xx/pull/12561) | `18oe_rulechanges` | Dividend options for minor/major/national | §6d: `dividend_types`, `HalfPay`, `change_share_price` |

---

_Last updated: 2026-05-01 — Full rewrite based on `18oe_testgame` (HEAD) and updated
`openpoints.md`. Major changes since 2026-04-25: §11 Nationals fully implemented
(1.1–1.8, 1.10–1.11 done; 1.9 partial); §12 Minor Mergers A–D all done; §6 stock market
complete (dividend types, RIGHT movement, post-conversion sell window); §8g train
obligation fully done; WA-3/WA-4 removed; §20 Outstanding PRs added._
