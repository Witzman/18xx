# 18OE — Implemented Game Mechanics

Documents every game mechanic that is currently implemented, from the rules perspective
(how a player experiences it), not the code perspective. Each item describes the rule,
then its status.

**Status markers:**
- `[x]` = fully working as the rules describe
- `[~]` = working but with a known gap or caveat (noted inline)
- `[ ]` = mechanic data is present but not functionally implemented

*Last verified: 2026-04-23 against codebase*

---

## 1. Game Setup & Company Structure

**Status**: Fully initialised. All 36 corporations and 10 privates load cleanly.

**Company tier structure** — the game has four company types:

- [x] **Minor corporations** (12): single 100% certificate at par £120. Auctioned in rows 7–12 as
  minor-exchange cards. Belong to a player until floated in the Regional/Minor Phase. Do not
  operate independently — they provide their owner with a home token location and special ability.
  Cannot buy trains.

- [x] **Regional corporations** (24): 3-certificate structure (50% president + 25% + 25%) with par
  prices £60/65/70/75/80/90. Float when treasurer receives 2× par. Operate in the Regional/Minor
  Phase within their home track-rights zone.

- [x] **Major corporations** (24): convert from floated regionals once the Major Railroad Phase
  begins. 9-certificate structure (20% president + 8×10%). Par prices £75/80/90/100/110/120.
  Additional six 10% treasury shares are issued on conversion.

- [~] **National corporations** (8): one per track-rights zone. Data structures complete (name,
  type `:national`, share structure). No formation logic exists — nationals cannot form in play yet.

- [x] **Starting cash** — £5,400 ÷ player count (3–7 players), rounded to nearest £10. £2,600
  for 2-player (without-concessions formula). Bank size £inf (no hard bank).

- [x] **Certificate limit** — standard engine rules; varies by player count.

---

## 2. Auction Phase

**Status**: Waterfall auction fully operational.

The Auction Phase uses a tiered waterfall structure. Companies are arranged in 12 rows
(6 privates/concessions at £20–£120 face value in rows 1–6; 12 minor-exchange cards in
rows 7–12, two per row). Only companies in the front available row may be purchased.

- [x] **Row gating** — only companies in the first available tier may be auctioned at any time;
  later rows are locked until the current row is cleared.

- [x] **Fixed-price purchase** — the active player may buy the cheapest available company in the
  front row at face value (no bidding required for direct purchase).

- [x] **Bidding** — players may bid on any company in the front row; minimum bid increment applies.
  Highest bid wins when the active player passes. If a player has an outstanding bid that is already
  highest, they may not bid on themselves.

- [x] **Minor company funding on purchase** — when a player buys a minor-exchange card (rows 7–12),
  the minor corporation's treasury receives the purchase price (capped at £180). The minor card
  remains with the player until they choose to float the minor in a subsequent Stock Round.

- [x] **All-pass round end** — auction phase ends when all players pass in sequence (standard
  waterfall behaviour).

- [x] **Privates / concessions remain with player** — all 10 privates and concession cards are
  defined and auctionable; they stay in the player's hand after purchase.

- [ ] **Private special abilities** — all 10 privates have their rulebook ability text in the UI
  but zero functional ability implementation. No ability fires during play.

- [ ] **Concession Railroad Phase** — 10 CON1–CON10 cards are defined and auctionable but the
  Concession float phase is explicitly deferred (§15 openpoints.md). After the auction the game
  proceeds directly to the Regional/Minor Stock Round.

---

## 3. Stock Market Mechanics

**Status**: Core share price movement working. Regional shares non-moveable by design.

The stock market is a standard 18xx 2-D staircase with two par-value tiers:

- [x] **Blue par tier** (regionals, £60–£90) — regional corporations par here; share price
  starts at the par price column, bottom row.

- [x] **Red par tier** (majors, £75–£120) — majors do not par directly; they convert from
  regionals and their initial market position is set by the conversion step.

### Share price movement

- [x] **LEFT** — when a corporation pays zero dividends (withholds), its share price moves
  one step left on the market.

- [x] **RIGHT** — when a corporation pays a dividend ≥ its current share price, the share
  price moves one step right.

- [x] **No movement** — when a corporation pays a dividend > 0 but < its share price, the
  share price does not move. Also: share price does not move at £550 (market edge).

- [x] **UP** (sold-out) — when all shares in a corporation are held by players at the end
  of a Stock Round, the share price moves up one row. Applies only to **majors** and
  **nationals**; regionals and minors never move up.

- [x] **DOWN** — each share sold by a player causes the share price to move one step down
  (base engine behaviour).

- [ ] **+3 RIGHT** — on the first Orient Express run by a major, the share price moves three
  additional steps right. Not yet implemented.

- [x] **Minors/regionals in operating order not affected by dividend movement** — corporations
  in `@minor_regional_order` (the floated minor/regional tracking list) have their share price
  change suppressed entirely. This is intentional: small companies have no market position
  to move.

### Stock Round actions (BuySellParShares step)

- [x] **Buy shares** — players may buy one share per turn from the bank pool or IPO.
  Buying from IPO is gated to Phase 4+ (Major Railroad Phase only).

- [x] **Sell shares** — players may sell shares from their hand to the bank pool. Regional
  shares cannot be sold. Shares of the corporation just converted in this turn cannot be sold.

- [x] **Par a regional** — a player who holds a regional's president certificate may set par,
  pay 2× par to the treasury, and float the regional. The par price is selected from the
  blue tier (£60–£90).

- [x] **Float a minor** — a player holding a minor-exchange card may set par and float the
  minor corporation. The minor card closes; the player receives the 100% minor share.
  Minor floats are tracked in `@minor_regional_order` (operating order list).

- [x] **Convert regional → major** (Major Phase only) — a regional corporation's president
  (or a 50%+ holder) may trigger conversion. The corporation type changes from `:regional` to
  `:major`, shares restructure to a 9-cert layout, six new 10% treasury shares are issued, and
  four additional token slots are added to the charter. The converting player must end up holding
  the president's certificate (20%); if not already president, they must immediately buy a share
  to claim the presidency. Stock market position adjusted (+2 right, +1 up) on conversion.

- [x] **Six unfloated regionals removed** — when the 18th regional is floated
  (`MAX_FLOATED_REGIONALS = 18`), all remaining unfloated regionals are closed immediately
  and the game transitions to the Major Railroad Phase.

- [x] **Track rights zone fee on par** — when a regional pars, the zone fee is deducted from
  its treasury immediately via `after_par` (UK/PHS £40; FR/AH £20; IT/SP/RU/SC £10).

- [x] **Home token placement during SR** — newly floated corporations may place their home
  token during the stock round (Step::HomeToken). The token placement is restricted to cities
  within the corporation's track-rights zone.

- [x] **Track rights zone restriction on home token** — token can only be placed in a city
  within the corporation's assigned zone (from `CORPORATIONS_TRACK_RIGHTS`). Placing in a zone
  that is already "locked" (another minor is tracking that zone) is blocked.

- [x] **Zone availability tracking** — `@minor_available_regions` tracks which zones still
  have unfloated minors in them; home token placement removes the zone from the available list.

---

## 4. Operating Round

**Status**: Core OR steps functional. Route revenue and advanced mechanics not yet complete.

### Step order (per operating corporation)

The OR step sequence for 18OE is:
1. Bankrupt check (base engine)
2. Exchange (base engine)
3. Discard train if over limit (base engine)
4. Home token placement if needed (HomeToken)
5. **Lay track** (Track)
6. **Place station token** (Token)
7. **Run routes** (Route — base engine)
8. **Pay dividends** (Dividend)
9. **Buy trains** (BuyTrain)
10. Issue shares (base engine)

### 4a. Track Laying (Step::Track)

Rules: each OR, a corporation may lay or upgrade track tiles, spending a point budget.
Minors/regionals have 3 points; majors 6 points; nationals 9 points (not yet active).
Point costs: yellow lay = 1 pt; upgrade (green/brown/gray) = 2 pt; yellow metropolis
lay = 2 pt; metropolis upgrade = 4 pt.

- [x] **Tile point budget** — tracked as `@points_used` within the step. Exhausting points
  ends the track phase. Remaining points displayed in the UI.

- [x] **Point costs by tile type** — yellow = 1 pt, upgrade = 2 pt, yellow metropolis = 2 pt,
  metropolis upgrade = 4 pt.

- [x] **Zone restriction** — track may only be laid within the corporation's home zone
  (minors/regionals) or any zone (majors/nationals). Implemented via
  `hex_within_national_region?`.

- [x] **Metropolis hex awareness** — point gating applied per hex when the hex is a metropolis
  (requires 2 pts for yellow lay, 4 pts for upgrade); ordinary hexes use standard costs.

- [x] **Cannot lay to blue (sea) hexes** — blue hexes are filtered out in `tracker_available_hex`.

- [x] **Label restrictions on upgrades** — cities with labels (A=Madrid/Vienna/Hamburg,
  B=Berlin, C=Constantinople, P=Paris, S=St Petersburg) only accept tiles carrying that
  same label. Implemented in `upgrades_to_correct_label?`.

- [~] **Terrain costs** — terrain cost data is encoded in map.rb for all regions (UK,
  Scandinavia, Alps, Spain/Portugal, Italy/Adriatic, Carpathians, Balkans, Caucasus,
  river crossings). However city **revenue values** are all placeholder 0, which means
  games run with effectively zero-revenue cities until map data is filled in.

- [ ] **National terrain exemption** — nationals pay no terrain costs per the rules. The
  `get_tile_lay` method returns `nil` for nationals (does not yet return 9 points).

- [ ] **Track rights zone discount** — IT/SP/RU/SC zones give 20% discount on terrain costs.
  Not yet implemented.

### 4b. Station Token Placement (Step::Token)

Rules: once per OR, a corporation may place one station token in a connected city within
its home zone (minors/regionals restricted to home zone; majors unrestricted).

- [x] **Zone restriction** — token can only be placed within the corporation's zone
  (`hex_within_national_region?`). Attempting to token outside the zone raises a GameError.

- [x] **Connectivity check** — the target city must be connected to the corporation's
  existing network via track. Disconnected placements are blocked.

- [ ] **Token transfer between majors** — a major may transfer a token to another of the
  same player's majors during this step (fee applies). Not yet implemented.

- [ ] **Ferry / sea-zone token costs** — +£20/ferry distance; +£40/sea zone. Not yet implemented.

### 4c. Route Running (Step::Route — base engine)

Rules: the corporation runs its trains along routes, collecting revenue from all visited
cities, towns, and off-board hexes.

- [~] **Route running** — base engine route logic handles path-finding and revenue calculation.
  Routes run correctly in principle, but all city revenues are placeholder 0, so revenue
  will be £0 for all routes until map data is filled in.

- [ ] **Cross-water costs** — ferry and sea-zone surcharges on routes not implemented.
- [ ] **Orient Express route detection** — OE bonus and mandatory run not implemented.
- [ ] **Local train town counting** — standard engine handles this; 18OE rules variant not confirmed.
- [ ] **Train combining for OE** — trains ≤Level 4 may combine for an OE run; not implemented.

### 4d. Dividends (Step::Dividend)

Rules: after running routes, the corporation pays out (full dividend), splits (half to
treasury, half distributed), or withholds (all to treasury). Nationals must pay all
revenue as dividends.

- [x] **Three dividend choices**: `payout` (full dividend), `half` (MinorHalfPay), `withhold`
  (zero dividend).

- [x] **Half-pay calculation** — withheld portion rounded down to nearest whole share unit;
  remainder distributed as per-share payout.

- [x] **Share price movement on dividend** — RIGHT if payout per share ≥ share price; LEFT if
  zero dividend; no move otherwise. Correctly skips movement for minors/regionals in the
  operating order list (they have no market position to move).

- [ ] **National dividend restriction** — nationals must pay all revenue as dividends (no
  withhold/split option). Not yet enforced.

### 4e. Train Purchases (Step::BuyTrain)

Rules: a floated corporation (not minor) may buy trains from the bank depot or (Phase 4+)
from other corporations. During Phase 2–3, each floated corporation must buy at least one
2+2 train on its first OR (the "train obligation").

- [x] **Floated corporation only** — minors are explicitly excluded from buying trains.

- [x] **Train obligation check** — `must_buy_train?` returns true if the corporation is floated,
  has no trains, and the current phase has `train_obligation` status (Phases 2–3 only).

- [x] **Obligation waived at Phase 4** — once Phase 4 starts, `train_obligation` status is no
  longer in `@phase.status`, so `must_buy_train?` returns false regardless of train count.

- [x] **Depot level gating** — only the cheapest available train level in the depot may be
  purchased; higher levels are locked until the current level is sold out.

- [x] **Inter-corporation purchase gated to Phase 4+** — `can_buy_train_from_others?` checks
  `phase.status.include?('can_buy_trains_from_others')` (active Phase 4+).

- [~] **2+2 obligation window (buyable_trains)** — the restriction to 2+2-only during the
  obligation window is implemented but **buggy**: it uses `entity.trains.empty?` (incorrectly
  re-restricts after a buy-across) and `phase.name.to_i < 4` (hard-coded integer, coding
  guidelines violation). See openpoints.md §3.1 for the fix.

- [ ] **Forced purchase / president contribution** — if a corporation cannot afford its
  mandatory train, the president must cover the shortfall. If still insufficient, the
  corporation enters insolvency (minors/regionals) or converts to national (majors). Not implemented.

- [ ] **Insolvency procedure** — president's cash → treasury; corporation gets reserved 2+2;
  presidential cert → Open Market; president receives face value. Not implemented.

- [ ] **Nationals claim rusted trains for free** — deferred.

---

## 5. Train System

**Status**: All train data correct. Phase gating and rusting work. Obligation logic
partially buggy (§4e above).

| Level | Type | Qty | Cost | Rusts at |
|---|---|---|---|---|
| 2 | 2+2 | 30 | £100 | Level 4 purchase |
| 3 | 3+3 / 3 | 20 | £225 / £200 | Level 6 purchase |
| 4 | 4+4 / 4 | 10 | £350 / £300 | Level 8 purchase |
| 5 | 5+5 / 5 | 8 | £475 / £400 | Never |
| 6 | 6+6 / 6 | 6 | £600 / £525 | Never |
| 7 | 7+7 / 4D | 14 | £750 / £850 | Never |
| 8 | 8+8 / 5D | 8 | £900 / £1000 | Never |

- [x] **Train quantities and costs** — all 7 train levels with correct quantities, face values,
  and variant types defined in `TRAINS`.

- [x] **Rusting** — 2+2 trains rust when the first Level 4 train is bought; 3+3/3 trains rust
  at Level 6; 4+4/4 trains rust at Level 8.

- [x] **Level 8 availability gate** — Level 8 trains only become available after the 4th Level 7
  train is purchased (`available_on:` in TRAINS). This is the only level with a deferred
  availability trigger.

- [x] **Train limits by phase** — PHASES defines train limits per company type:
  - Phases 1–3: minor/regional limit 2; major limit 4
  - Phase 4: minor/regional limit 1; major limit 3; national limit 4
  - Phases 5–6: minor/regional must have merged; major limit 2; national limit 3
  - Phases 7–8: major limit 3; national limit 4

- [ ] **Pullman cars** — not implemented. Pullman is a separate asset (not a train) that adds
  +£10 × train level to one train's revenue per OR. Minor M starts with 10 Pullmans.

---

## 6. Phase Progression

**Status**: All 8 phases defined with correct status flags and events. Phase transitions
fire correctly.

- [x] **8 game phases** — defined in PHASES with train limits, tile colour unlocks,
  operating rounds, and status flags.

- [x] **Phase 2 (2+2 trains)** — `train_obligation` status active. Tile colours: yellow only.

- [x] **Phase 3 (3+3 trains)** — `train_obligation` status still active. Yellow + green tiles.

- [x] **Phase 4 (4+4 trains)** — `train_obligation` removed; `can_buy_trains_from_others` status
  added. Yellow + green + brown tiles. 2+2 trains rust.

- [x] **Phase 5 event** — `event_consolidation_triggered!` fires, setting `@consolidation_triggered`.
  The next `next_round!` after the current OR set routes to the Consolidation round.

- [x] **Phase 6 (6+6 trains)** — 3+3/3 trains rust.

- [x] **Phase 8 (8+8 trains)** — 4+4/4 trains rust. Level 8 trains unlock after 4th Level 7 purchase.

- [x] **Tile colour progression** — track step correctly gates available tile colours by phase
  (base engine `@phase.tiles` integration).

---

## 7. Map & Terrain

**Status**: Map geometry complete. Revenue values placeholder 0 throughout. Sea zone
hex lists defined; no ferry mechanics encoded.

- [x] **Grid and layout** — `LAYOUT = :pointy`, `AXES = { x: :number, y: :letter }`, 34 rows
  (A–AH), columns 2–88.

- [x] **651 blue sea hexes** — all sea hexes defined as blank blue tiles; impassable for track.

- [x] **19 red off-board hexes** — all coordinates correct; revenues encoded as best-guess
  phase-based values (y/g/b/gray); path edges implemented.

- [x] **All land hexes** — all land hexes present; cities/towns have `city=revenue:0` or
  `town=revenue:0` geometry from cities.csv; double-town hexes correctly typed.

- [x] **Terrain costs encoded** — mountain/water/hill costs implemented for: UK/Ireland,
  France, Spain/Portugal, Scandinavia, Alps, Italy, Adriatic, Carpathians, Balkans,
  Caucasus, and major river crossings (Rhine/Elbe/Vistula/Bug/Dnieper corridors).

- [x] **255 LOCATION_NAMES** — all named cities and towns labelled in the UI.

- [x] **Pre-printed yellows (yellow section)** — Liverpool J25 (rev 30, edges 2+4, label Y),
  Manchester J27 (rev 20, edges 1+4, mountain), Athinai AE72 (rev 20, edges 1+5).

- [~] **Partial pre-printed cities (white section)** — London M28, Constantinople AA82, Napoli
  AB51 have revenues set but are still in the white section (path edges not yet confirmed;
  cannot be moved to yellow section until edges are known).

- [~] **Off-board revenues** — 19 red hexes have best-guess phase revenues. Values need
  verification against the physical map.

- [ ] **City starting revenues** — all land hexes have `revenue:0` placeholder. Actual
  starting revenues not yet filled in. This means all route revenue in play is £0.

- [x] **SEA_ZONES defined** — 19 named sea zones with complete hex lists (Celtic Sea, North
  Atlantic Ocean, North Atlantic Silver Coast, Bay of Biscay, English Channel, North Sea,
  Skagerrak, German Bight, Gulf of Finland, Baltic Sea, Strait of Gibraltar, Balearic Sea,
  Sea of Sardinia, Tyrrhenian Sea, Adriatic Sea, Aegean Sea, Levantine Sea, Black Sea,
  Karkinitsky Bay).

- [ ] **Ferry paths and borders** — no ferry path or impassable sea-border encoding done.

- [ ] **Port markers, sea-zone distances** — not encoded.

- [ ] **Cross-water costs in routes** — ferry/sea surcharges not implemented.

---

## 8. National Region Hexes & Zone System

**Status**: All data structures complete. No formation or revenue logic.

The game has 8 national zones (UK, SC, FR, PHS, AH, IT, SP, RU), each corresponding to a
national corporation and a group of land hexes. Regional and minor corporations are
restricted to laying track and tokens within their assigned zone.

- [x] **NATIONAL_REGION_HEXES (8 zones)** — all zones defined with complete hex lists.
  `NATIONAL_REGION_HEXES_COMPLETE = true`.

- [x] **CITY_NATIONAL_ZONE border overrides** — border-city Q38 → FR zone; O52 → PHS zone.

- [x] **MINOR_EXCLUDED_HOME_CITIES** — list of cities that minors cannot choose as home token.

- [x] **Zone restriction enforcement in Track and Token steps** — both steps call
  `hex_within_national_region?` to enforce that minors/regionals stay in their zone.

- [x] **`@minor_available_regions` tracking** — dynamically derived from regional corporations;
  updated as minors float and claim their zone.

- [x] **`@minor_floated_regions` tracking** — maps minor corp ID → zone string after home
  token placement.

- [~] **Two stale entries** — `NATIONAL_REGION_HEXES['SC']` still contains `A40` (now blue)
  and `NATIONAL_REGION_HEXES['RU']` still contains `E88` (removed from map). Both must be
  removed before national formation is implemented.

- [ ] **National formation trigger** — nationals form when trains of Level 4/6/8 are first
  purchased. No trigger, no formation step, no national revenue method yet.

---

## 9. Custom Tiles (OE Series)

**Status**: Most custom tiles defined. Double-town variants and one unknown tile still missing.

- [x] **OE1–OE3**: yellow double-town tiles (3 orientations, qty 4/6/2). Implemented.
- [x] **OE4–OE8**: yellow special city tiles (grand cities and metropolises). Implemented.
- [ ] **OE9–OE11**: green double-town tiles (qty 3/3/3). Commented out — path orientations unknown.
- [x] **OE12–OE18**: green special city tiles. Implemented.
- [ ] **OE19**: unknown tile type. Not defined; gap between OE18 (green) and OE20 (brown).
- [ ] **OE20–OE22**: brown double-town tiles (qty 3/2/6). Commented out — path orientations unknown.
- [x] **OE23–OE33**: brown special city tiles. Implemented.
- [x] **OE34–OE44**: gray special city tiles. Implemented.

---

## 10. Consolidation Phase

**Status**: Trigger and round scaffold only. No player actions implemented.

The Consolidation Phase occurs once, after the first Stock Round following Phase 5. All
remaining minors and regionals must either merge into a major/national or be abandoned.

- [x] **Phase 5 event trigger** — `event_consolidation_triggered!` sets `@consolidation_triggered`
  flag and logs the event.

- [x] **Round routing** — `next_round!` detects `@consolidation_triggered` and routes to
  `Round::G18OE::Consolidation` instead of the normal next round (fires only once;
  `@consolidation_done` prevents re-entry).

- [x] **Consolidation round scaffold** — `Round::G18OE::Consolidation` with `Step::Consolidate`
  exists and loads cleanly.

- [~] **Step::Consolidate** — only `pass` action is implemented. A player can acknowledge and
  pass through their consolidation turn, but no merge or abandon actions are wired.

- [ ] **Merge action** — minor/regional owner solicits offers from eligible majors/nationals;
  player accepts offer; assets transfer. Not implemented.

- [ ] **Abandon action** — player abandons minor/regional; assets forfeited; charter closed.
  Not implemented.

- [ ] **Cannot-pass enforcement** — players owning unfloated minors/regionals cannot skip the
  consolidation step. Not yet enforced.

---

## 11. Stock Round Structure (Operating Order)

- [x] **Operating order** — `operating_order` returns `@minor_regional_order` (in float order)
  followed by all majors and nationals sorted by share price descending.

- [x] **Minors/regionals operate in float order** — floated minor/regional corporations are
  appended to `@minor_regional_order` as they float, and operate in that sequence.

- [x] **Majors operate in share-price order** — `@corporations.select { major/national }.sort`
  uses the engine's default share-price sort.

- [x] **Major removed from minor/regional order on conversion** — when a regional converts to
  major, it is removed from `@minor_regional_order` and thereafter operates in share-price order.

---

## 12. Issuable Shares (Majors)

- [x] **Majors can issue treasury shares** — `issuable_shares` returns treasury share bundles
  for major corporations that fit in the bank pool. Minors and regionals cannot issue.

---

## 13. Mechanics Not Yet Started

The following rule areas have zero implementation (not even a scaffold):

| Mechanic | Rules section |
|---|---|
| Orient Express bonus + route + RIGHT×3 | Rulebook §7.4 |
| Pullman cars (all variants) | Rulebook §7.5 |
| Minor special abilities (A–M) | Rulebook §15 |
| Private special abilities (all 10) | Rulebook §14 |
| National formation + revenue | Rulebook §8 |
| Forced purchase / insolvency | Rulebook §7.3 |
| Token transfer between majors | Rulebook §7.2 |
| Cross-water costs (ferry + sea zones) | Rulebook §6 |
| Ferry mechanics + port markers | Rulebook §6 |
| Minor merger rules | Rulebook §9 |
| End game (bank break, final two ORs) | Rulebook §11 |
| Concession Railroad Phase | Rulebook §4.2 (deferred) |
