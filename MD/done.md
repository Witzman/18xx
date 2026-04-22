# 18OE — Implemented Features

Implemented features as of branch `18oe_fullmap` (last checked 2026-04-23).
Explanations are based on rules, not code. Grouped to mirror `openpoints.md`.

**Engine layer annotations** (see `MD/ENGINE_MECHANICS.md` for full explanation):
- **L1** = Layer 1: pure constants, no custom Ruby methods needed
- **L2** = Layer 2: named `Game::Base` method override
- **L3** = Layer 3: new step or round Ruby class required
- **L4** = Layer 4: structural engine divergence (none in 18OE)

---

## 1. Nationals

Structural data required for national formation and revenue is complete. No
formation or revenue logic runs yet; these items are prerequisites for §1.2–1.9.

- [x] **1.1** National corporation type `:national` in train limits — each phase defines
  the correct train limit for nationals (4 in Phase 4; 3 in Phases 5–6; 4 in Phases 7–8) **[L1]**
- [x] **1.10** All 8 national zone hex lists defined (`NATIONAL_REGION_HEXES`: UK, SC, FR, PHS, AH, IT, SP, RU);
  `NATIONAL_REGION_HEXES_COMPLETE = true` set; border-city zone overrides (`CITY_NATIONAL_ZONE`) defined;
  list of cities barred from minor home-token placement (`MINOR_EXCLUDED_HOME_CITIES`) defined **[L1]**
- [x] **1.11** Available minor home-token regions (`@minor_available_regions`) built
  dynamically from the actual regional corporation list at game start, not a hard-coded
  copy — so it stays correct if the corporation list changes **[L1/L2]**

---

## 2. Base Game Entities + Map

All company definitions are complete. The map is created and loadable with full terrain
and all named locations, though city revenues remain placeholder.

### 2a. Company Definitions (entities.rb)

- [x] **2.1** All 24 regional corporations defined — home city coordinates, track rights
  zone assignments, correct certificate split (50%+25%+25%), par range £60–£90 **[L1]**
- [x] **2.2** All 12 minor corporations defined — type `:minor`, single 100% certificate,
  fixed par £120, description text for each special ability from the rulebook **[L1]**
- [x] **2.3** All 10 private companies defined — face values, revenue, rulebook description
  text for each ability **[L1]**
- [x] **2.4** All 12 minor auction cards defined — buying the card in the auction gives the
  player the right to float the corresponding minor corporation in the Regional/Minor Phase **[L1]**
- [x] **2.5** All 10 concession cards (CON1–CON10) defined as entities *(Concession Phase
  itself is deferred — see §15)* **[L1]**

### 2b. Map (map.rb)

- [x] Full grid — 651 blue sea/blank hexes covering the whole map area **[L1]**
- [x] All 19 red off-board hexes implemented with best-guess revenues (pending verification
  against physical map) **[L1]**
- [x] All terrain costs applied: mountains/Alps, rough terrain (Carpathians/Balkans/Caucasus),
  water crossings (UK, Ireland, Adriatic, rivers) **[L1]**
- [x] 255 location names (`LOCATION_NAMES`) — every named city, town, and off-board label
  from the rulebook map **[L1]**
- [x] All 255 named locations carry a station slot with placeholder revenue 0 — sufficient
  for game initialisation and track laying **[L1]**
- [x] Pre-printed yellow tiles: Liverpool (J25) and Manchester (J27) start on yellow tiles
  with their printed revenues; Athinai (AE72) placed in its yellow section **[L1]**
- [x] All 8 national zone hex lists embedded in `NATIONAL_REGION_HEXES` — used for token
  zone restrictions and (eventually) national revenue **[L1]**
- [x] `SEA_ZONES` constant — 19 named sea zones each with their hex lists defined, ready for
  cross-water cost calculations **[L1]**

---

## 3. Train Mechanics

The core train roster and purchase rules are in place. The reserved 2+2 obligation and
forced purchase logic have partial implementation; insolvency is not yet done.

### 3a. Train Roster

- [x] Full 7-level train roster: 2+2, 3/3+3, 4/4+4, 5/5+5, 6/6+6, 7+7/4D, 8+8/5D **[L1]**
- [x] Correct quantities per level (30, 20, 10, 8, 6, 14, 8) **[L1]**
- [x] Correct face values for every train and local variant **[L1]**
- [x] Rust triggers: 2+2 trains rust when the first Level 4 train is purchased;
  3-level trains rust when the first Level 6 train is purchased **[L1]**
- [x] Level 8 trains become available only after the 4th Level 7 purchase — this fires
  as a game event, not at a fixed phase boundary **[L1]**
- [x] Consolidation trigger event fires when first Level 5 train is purchased,
  marking the start of the Consolidation Phase at the next SR **[L1]**

### 3b. Purchase Rules

- [x] **3.4** Reserved 2+2 obligation is automatically waived if Phase 4 arrives before a
  company has had its first Operating Round — checked via phase status flag, not a
  hard-coded phase number **[L2]**
- [x] **3.5** Depot level gating — a company may only buy the cheapest available train level
  from the depot (cannot skip levels) **[L2]**
- [x] **3.6** Purchasing a train from another railroad is permitted only from Phase 4 onwards;
  blocked in Phases 2–3 **[L2]**

---

## 4. Stock Market

The full stock market grid, par colour bands, and three of the four movement directions
are implemented.

- [x] Stock market grid — 8 rows × 17 columns with correct prices; highest cell (£550)
  is the no-movement ceiling **[L1]**
- [x] Par colour bands — blue cells mark regional par values (£60–£90); red cells mark
  major par values (£75–£120) **[L1]**
- [x] **4.1** LEFT movement — a company that pays zero dividend moves its share price one
  step to the left **[L2]**
- [x] **4.2** No movement — a company that pays a dividend greater than zero but less than
  its current share price does not move **[L2]**
- [x] **4.3** UP movement at end of SR — a company whose shares are all held by players
  (none in the bank pool or treasury) moves one step up; restricted to majors and
  nationals only, not regionals **[L2]**
- [x] Minors and regionals in the operating order do not trigger stock movement when they
  pay dividends (they are not publicly traded companies at that stage) **[L2]**

---

## 5. Orient Express Mechanic

No Orient Express logic is implemented yet. See `openpoints.md §5`.

---

## 6. Pullman Cars

No Pullman car logic is implemented yet. See `openpoints.md §6`.

---

## 7. Minor Special Abilities

Rulebook descriptions are in place for all 12 minors; no ability runs in the game engine yet.

- [x] All 12 minor ability texts from the rulebook entered as `desc:` in the minor
  definitions — A (Silver Banner), B (Orange Scroll), C (Golden Bell), D (Green Junction),
  E (Blue Coast), F (White Peak), G (Indigo Foundry), H (Great Western Steamship),
  J (Grey Locomotive Works), K (Vermilion Seal), L (Krasnaya Strela), M (CIWL) **[L1]**

---

## 8. Private Special Abilities

Rulebook descriptions are in place for all 10 privates; no ability runs in the game engine yet.

- [x] All 10 private ability texts from the rulebook entered as `desc:` — Wien Südbahnhof,
  Barclay Bevan Barclay & Tritton, Star Harbor Trading Co., Central Circle Transport Corp.,
  White Cliffs Ferry, Hochberg Mining & Lumber, Brandt & Brandau Engineers, Swift
  Metropolitan Line, plus the two no-ability privates (Robert Stephenson and Co.,
  Ponts et Chaussées) **[L1]**

---

## 9. Tile Definitions

Yellow and most coloured OE tiles are defined. Green/brown double-town tiles (OE9–11,
OE20–22) and OE19 are still missing.

- [x] **OE1–OE3** — yellow double-town tiles (quantities 4, 6, 2) **[L1]**
- [x] **OE4–OE8** — yellow metropolis/special-city tiles **[L1]**
- [x] **OE12–OE18** — green special-city tiles **[L1]**
- [x] **OE23–OE33** — brown special-city tiles **[L1]**
- [x] **OE34–OE44** — gray special-city tiles **[L1]**
- [x] Tile point cost rules encoded — yellow lay costs 1 point; an upgrade costs 2 points;
  a metropolis upgrade costs 4 points **[L2]**
- [x] Point budgets enforced per company type — minors and regionals have 3 points per OR;
  majors have 6 points **[L2]**
- [x] `TILE_UPGRADES_MUST_USE_MAX_EXITS` enforced for cities — a city tile must use the
  maximum number of exits available when upgraded **[L1]**
- [x] Metropolis upgrade label enforcement — upgrade paths for Amsterdam (A), Berlin (B),
  Constantinople (C), Paris (P), and Sankt-Peterburg (S) labelled tiles verified **[L2]**

---

## 10. Route & Revenue Rules

No cross-water cost or route-restriction logic is implemented yet. See `openpoints.md §10`.

---

## 11. Consolidation Phase

The trigger and round scaffolding are in place; merge and abandon actions are not yet implemented.

- [x] **11.1** Consolidation trigger — when the first Level 5 train is purchased the game
  records a consolidation event; after the current pair of Operating Rounds completes,
  the next round is a Consolidation Round (fires once only) **[L1/L2]**
- [~] **11.2** Consolidation Round exists as a named round type with a Consolidate step that
  identifies which player-owned minors and regionals must be resolved — merge and abandon
  actions are not yet handled **[L3 scaffold]**

---

## 12. Token Transfer Between Majors

Not implemented. See `openpoints.md §12`.

---

## 13. Minor Merger Rules

Not implemented. See `openpoints.md §13`.

---

## 14. End Game Rules

Not implemented. See `openpoints.md §14`.

---

## 15. Concession Railroad Phase (DEFERRED)

The 10 concession cards are defined as entities (§2.5 above). The Concession Round
itself is explicitly deferred and will not be implemented in the current pass. The
2-player without-concessions starting cash (£2,600) is already in `STARTING_CASH`.

---

## 16. Tests

No automated tests exist for 18OE yet.

---

## 17. Variants

No variant-specific items are confirmed implemented beyond the shared base. The UK-FR
variant (`g_18_oe_uk_fr`) has its own entity and map files but is out of scope for the
current development pass.

---

## Cross-Cutting Mechanics (not in openpoints.md)

These items do not correspond to a numbered open point but are fully implemented and
foundational for play.

### Player Count and Bank
- **Player range**: 2–7 players **[L1]**
- **Starting cash**: £5,400 ÷ number of players for 3–7 players (rounded to nearest £5);
  £2,600 flat for 2-player (the without-concessions formula from the Playbook) **[L1]**
- **Bank size**: £54,000 **[L1]**
- **Certificate limits** defined for all player counts (2: unlimited; 3: 48; 4: 36; 5: 29;
  6: 24; 7: 20) **[L1]**

### Company Structure and Capitalisation
- Three-tier company hierarchy — minor (1 cert, 100%) → regional (3 certs, 50%+25%+25%) →
  major (9 certs, 20%+8×10%) → national (9 certs, inherits major) **[L1]**
- Incremental capitalisation — treasury grows as shares are sold, not upfront float **[L1]**
- Float condition: pay 2× par to regional treasury; major floats by converting from regional **[L2]**
- Regionals cannot be dumped (blocked from sale after purchase in a single turn) **[L2]**

### Auction Phase
- Waterfall auction with tiered rows — only the cheapest available row may be purchased
  outright; higher rows require a bid **[L3]**
- Buying a minor's auction card provides the right to float that minor later;
  the minor receives its fixed £120 par capital (capped at £180 from the auction price)
  at the time of card purchase **[L3]**

### Track Rights Zones
- All 8 track rights zones fully defined (UK, PHS, FR, AH, IT, SP, RU, SC) **[L1]**
- Zone fees paid automatically when a regional par price is set:
  UK/PHS £40; FR/AH £20; IT/SP/RU/SC £10 **[L2]**
- Minor home-token placement restricted to available zones; selecting a minor from
  UK, PHS, or FR counts against the combined 4-selection cap for those three zones **[L3]**
- Token placement for regionals and minors restricted to their own track rights zone **[L2]**
- Minor zone recorded at home-token placement and used for all subsequent zone checks **[L2]**

### Operating Order
- Companies operate in the order they floated (minors and regionals first, in float order),
  then majors and nationals sorted by share price **[L2]**

### Dividend Options
- Three options: full payout, half pay (half to treasury, half to shareholders), withhold **[L1/L2]**
- Half-pay calculation rounds withheld amount down to a share-exact multiple **[L2]**

### Stock Round Structure
- Sell-then-buy order within a player's turn **[L1]**
- Home token placement available during the Stock Round (minors float here) **[L3]**
- Regional → major conversion available from Major Phase onwards **[L2]**
- Share issuance available for majors (selling treasury shares into the bank pool) **[L2]**

---

_Last updated: 2026-04-23 — Checked against `18oe_fullmap` branch._
