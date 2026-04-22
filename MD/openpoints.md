# 18OE — Open Points

Tracked implementation gaps based on rulebook analysis (v1.0). Items are grouped by
area and roughly prioritized. Earlier items are more foundational.

**Engine layer annotations** (see `MD/ENGINE_MECHANICS.md` for full explanation):
- **L1** = Layer 1: pure constants, no custom Ruby methods needed
- **L2** = Layer 2: named `Game::Base` method override
- **L3** = Layer 3: new step or round Ruby class required
- **L4** = Layer 4: structural engine divergence (none in 18OE)

---

## 1. Nationals

**Status 2026-04-22**: Data structures in place (`PHASES` train limits,
`NATIONAL_REGION_HEXES` all 8 zones complete). No implementation code yet —
`convert_to_national`, `national_revenue`, `trigger_nationals_formation!` are absent
from game.rb and no `step/convert_to_national.rb` exists.

Note: `NATIONAL_REGION_HEXES` has two stale map-change entries — SC still lists A40
(now blue sea hex) and RU still lists E88 (removed entirely); fix both before nationals
implementation (see §2.7 bugs).

- [x] **1.1** National corporation type `:national` data — `PHASES` train limits,
  `NATIONAL_REGION_HEXES` all 8 zones, `NATIONAL_REGION_HEXES_COMPLETE = true` **[L1]**
- [ ] **1.2** National formation trigger — `Step::BuyTrain#process_buy_train` must detect
  phase change to 4/6/8 and call `game.trigger_nationals_formation!(buyer_player)`; players
  queued buyer-first **[L2]**
- [ ] **1.3** National formation steps in `convert_to_national` (game.rb): **[L2/L3]**
  - [ ] Major's cash → bank
  - [ ] All major treasury certs → Open Market
  - [ ] Remove all major tokens from map
  - [ ] Abandon any merged minors *(deferred)*
  - [ ] Remove track rights, OE markers, private markers *(deferred)*
  - [ ] National operates in share-value sort bucket (same as majors)
  - [ ] National inherits all trains
- [ ] **1.4** National revenue calculation — `national_revenue` in game.rb: **[L2]**
  - [ ] Virtual tokens via `Graph.new(home_as_token: true, no_blocking: true)`
    (requires non-zero city revenues first)
  - [ ] Linked cities/towns at face value, best-first up to capacity
  - [ ] Remaining capacity fills at £60/city, £10/town
  - [ ] D trains doubling linked cities *(deferred)*
  - [ ] Must pay ALL revenue as dividends — `dividend_types` returns `[:payout]` only
- [ ] **1.5** Inherent Pullman bonus: +£10 × level of highest non-rusted train in
  `national_revenue` **[L2]**
- [ ] **1.6** Nationals cannot place tokens — `Token#actions` must return `[]` for
  nationals **[L2]**
- [ ] **1.7** Nationals exempt from terrain costs — `tile_cost_with_discount` returns 0
  for nationals **[L2]**
- [ ] **1.8** National train limits already in `PHASES`; `convert_to_national` must
  discard cheapest excess trains on formation **[L2]**
- [ ] **1.9** Nationals can claim rusted trains for free *(deferred)* **[L3]**
- [x] **1.10** `NATIONAL_REGION_HEXES` all 8 zones defined; `NATIONAL_REGION_HEXES_COMPLETE
  = true`; `CITY_NATIONAL_ZONE` border overrides; `MINOR_EXCLUDED_HOME_CITIES` defined **[L1]**
- [x] **1.11** `@minor_available_regions` derived dynamically from regionals **[L1/L2]**

---

## 2. Base Game Entities + Map ~~(2.1–2.5 done; 2.6 in progress; 2.7 structural done)~~

`g_18_oe/entities.rb` complete. `g_18_oe/map.rb` created and loadable; full terrain done
(Carpathians/Balkans/Caucasus/rivers); 651 blue hexes; 19 red offboards with best-guess
revenues; 255 location names; city revenues still TBD.

- [x] **2.1** Define all 24 regionals — home cities/coords, track rights zones **[L1]**
- [x] **2.2** Define all 12 minors — type `:minor`, tokens, shares, `desc:` ability text **[L1]**
- [x] **2.3** Define all 10 privates with face values, revenues, `desc:` ability text **[L1]**
- [x] **2.4** Minor-exchange auction cards for all 12 minors **[L1]**
- [x] **2.5** Define 10 concession cards (CON1–CON10) *(concession phase deferred — §15)* **[L1]**
- [ ] **2.6** Logo artwork — grey circle stubs for 25 corporations **[non-code]**:
  - Minors (8): A, B, D, E, F, G, J, L
  - Regionals (17): BHB, POB, KSS, KBS, SB; MAV, SFAI, SFR; CHN; MZA, RCP; MSP, MKV,
    LRZD; WW, DSJ, BJV
  - Already have real logos: LNWR, GWR, GSWR (UK); PLM, MIDI, OU, BEL (FR); minors C/H/K/M
- [~] **2.7** Base-game map `g_18_oe/map.rb`:
  - [x] Full grid coverage — 651 blue hexes
  - [x] 19 red off-board hexes implemented
  - [x] All terrain costs: UK/FR/Spain/Portugal/Scandinavia/Alps/Italy/Adriatic/
    Carpathians/Balkans/Caucasus/river crossings
  - [x] LOCATION_NAMES: 255 entries
  - [x] Pre-printed yellows: Liverpool J25, Manchester J27, Athinai AE72 (yellow section)
  - [x] Station markers: all 255 named locations have `city=revenue:0` or `town=revenue:0`
  - [x] NATIONAL_REGION_HEXES all 8 zones; CITY_NATIONAL_ZONE overrides
  - [~] Constantinople AA82: white section, two city slots, revenue 20/slot — path edges
    needed; must move to yellow section when edges confirmed
  - [ ] City revenues: all hexes have placeholder `revenue:0` — actual starting revenues
    needed from physical map **[HIGH PRIORITY]**
  - [ ] **Pre-printed path edges missing** (8 cities in white section pending edge confirm):
    - M28 London — `city=revenue:30;label=L;upgrade=cost:30,terrain:water` — both edges
    - AA82 Constantinople — both edges
    - AB51 Napoli — second edge (has edge 1)
    - N31 Lille — both edges
    - I20 Dublin — both edges
    - O28 Le Havre — both edges
    - X33 Marseille — both edges
    - U24 Bordeaux — both edges
  - [~] Off-board revenues: 19 red hexes have best-guess revenues — need verification
  - [ ] Sea zone borders, ferry paths, distance numbers not encoded
  - [ ] **Bug**: AB51 Napoli `path=a:1,b:_0` — edge 1 goes to blue sea hex AC52;
    `all_new_exits_valid` fails making AB51 unupgradeable. Fix: correct non-sea edge or
    implement sea-crossing neighbour support
  - [ ] **Bug**: `game.rb#metropolis_hex?` still lists `BB51` — must be `AB51` (Napoli)
  - [ ] **Bug**: `game.rb#upgrades_to_correct_label?` missing case for `AB51` (label=N) —
    add `when 'AB51' then to.label.to_s.include?('N')`
  - [ ] **Bug**: `NATIONAL_REGION_HEXES['SC']` still contains `A40` — remove (now blue)
  - [ ] **Bug**: `NATIONAL_REGION_HEXES['RU']` still contains `E88` — remove (removed from map)

---

## 3. Train Mechanics (`step/buy_train.rb`) — [L2/L3]

Partially implemented (2026-04-12): 2+2 obligation, depot level gating, inter-corp
train gate are in. President shortfall relies on base engine. Insolvency and
nationals-claim-rusted deferred.

**Confirmed train data:**

| Level | Local/Express | Qty | Face Value | Rusts at |
|---|---|---|---|---|
| 2 | 2+2 / — | 30 | £100 | Level 4 |
| 3 | 3+3 / 3 | 20 | £225 / £200 | Level 6 |
| 4 | 4+4 / 4 | 10 | £350 / £300 | — |
| 5 | 5+5 / 5 | 8 | £475 / £400 | — |
| 6 | 6+6 / 6 | 6 | £600 / £525 | — |
| 7 | 7+7 / 4D | 14 | £750 / £850 | — |
| 8 | 8+8 / 5D | 8 | £900 / £1000 | — |

Level 8 trains become available after the 4th Level 7 train is purchased.

- [~] **3.1** Reserved 2+2 train — `buyable_trains` restriction buggy **[L2]**:
  - ✓ `must_buy_train?` correctly uses `@game.phase.status.include?('train_obligation')`
  - **Bug**: `buyable_trains` still uses `entity.trains.empty?` (wrong — trips on buy-across)
    and `@game.phase.name.to_i < 4` (coding-guidelines Issue 1 — hard-coded phase integer)
  - **Fix needed**: add `@fulfilled_train_obligation = Set.new` in `game.rb#setup`; record
    entity in set when first train purchased (`entity.trains.one?`); replace both checks
    in `buyable_trains` with `!@game.fulfilled_train_obligation.include?(entity.id)` and
    `@game.phase.status.include?('train_obligation')`
- [ ] **3.2** Forced purchase — president covers shortfall; if insufficient, RR converts
  to national (majors) or insolvency (minors/regionals) *(president contribution relies
  on base engine `president_may_contribute?`; national/insolvency conversion deferred)* **[L3]**
- [ ] **3.3** First-round insolvency: president's cash → treasury; RR gets reserved 2+2;
  presidential cert → Open Market; president gets face value payment **[L3]**
- [x] **3.4** Reserved 2+2 obligation waived if Phase 4 starts before first OR —
  `must_buy_train?` uses `phase.status.include?('train_obligation')` (no longer hard-coded) **[L2]**
- [x] **3.5** Depot level gating — `buyable_trains` filters to cheapest available level only **[L2]**
- [x] **3.6** Train purchase from other RRs gated to Phase 4+ — `can_buy_train_from_others?` **[L2]**
- [ ] **3.7** Nationals claim rusted trains for free *(deferred)* **[L3]**

---

## 4. Stock Market Movement — [L2]

- [x] **4.1** LEFT movement — zero dividend triggers `share_direction: :left`
- [x] **4.2** No movement — dividend > 0 but < share value returns `{}` (correct no-op)
- [x] **4.3** UP movement — `sold_out_increase?` gates UP to `:major`/`:national` only;
  base engine `finish_round` → `sold_out_stock_movement` → `move_up` at SR end
- [ ] **4.4** +3 RIGHT — on first Orient Express run by a major (in addition to normal
  dividend movement) **[L2]**

---

## 5. Orient Express Mechanic — [L2/L3]

- [ ] **5.1** Detect valid OE route: Constantinople + one of Paris/London/Berlin/Madrid/
  Sankt-Peterburg; must include some land track **[L2 `check_other`]**
- [ ] **5.2** First-time bonus: £30 (Phase 2–4), £60 (Phase 5–6), £100 (Phase 7–8);
  bank pays to treasury; place OE marker on major **[L2 `revenue_for` + `action_processed`]**
- [ ] **5.3** Stock marker moves RIGHT×3 on first OE run (in addition to dividend move) **[L2]**
- [ ] **5.4** Train combining for OE: levels ≤4 combine (combined level = sum); 5+/4D/5D
  cannot combine **[L2 `check_distance`]**
- [ ] **5.5** Subsequent OE runs: no bonus, no extra stock movement **[L2]**
- [ ] **5.6** Mandatory OE: if OE route is best possible, president must run it **[L2]**
- [ ] **5.7** OE blocked for nationals — needs explicit `routes_revenue` bypass **[L2]**
- [ ] **5.8** D-train bonus does NOT apply to OE first-time bonus **[L2]**

---

## 6. Pullman Cars — [L3]

- [ ] **6.1** Pullman asset type — doesn't count against train limit; max 1 per non-national **[L3]**
- [ ] **6.2** Revenue: +£10 × train level added to one train's revenue per OR **[L2/L3]**
- [ ] **6.3** From Minor M: £150 (+ £15 royalty); J-minor discount on price not royalty **[L3]**
- [ ] **6.4** From Open Market: £150 no royalty; available Phase 4+ **[L3]**
- [ ] **6.5** From another RR: negotiated price **[L3]**
- [ ] **6.6** Nationals: inherent Pullman — computed in `national_revenue` *(depends on 1.4)* **[L2]**
- [ ] **6.7** Minor M free Pullman at Phase 4 start if M not yet closed **[L2/L3]**
- [ ] **6.8** Discard rules — rusted trains first; Pullman voluntary discard to Open Market **[L3]**
- [ ] **6.9** RR with zero trains + Pullman: Pullman stays until next train acquired **[L3]**

---

## 7. Minor Special Abilities — [L3]

**Status: descriptions only.** All 12 minors have rulebook `desc:` text in `entities.rb`.
Zero functional `abilities:` entries. No transfer-on-merge mechanism.

See `MD/ABILITIES_REFERENCE.md §2` for ability types needed for each minor.

- [ ] **7.1** Ability transfer mechanism — when minor merges with major, minor's charter
  placed under major's (ability inherited); nationals cannot inherit abilities **[L3]**
- [ ] **7.2** Minor A (Silver Banner): bank pays major = current share value on merge **[L3]**
  *Implementation*: hook in `game.rb#merge_minor`
- [ ] **7.3** Minor B (Orange Scroll): all track upgrades cost 1 tile point (not
  cities/grand cities/metropolises) **[L2 `tile_lays`/`tile_cost`]**
- [ ] **7.4** Minor C (Golden Bell): president chooses operating position each OR **[L3]**
  *Implementation*: `choose_ability` + custom `operating_order` hook
- [ ] **7.5** Minor D (Green Junction): token in any non-metro/non-red-zone city; £20/£40
  bonus by phase; removed at Phase 5 start **[L3]**
  *Implementation*: `token` (free) + `hex_bonus` (phase-conditional) + cleanup at phase event
- [ ] **7.6** Minor E (Blue Coast): 33% discount on blue terrain; +1 tile pt in blue hexes **[L2]**
  *Implementation*: `tile_discount` (terrain: water) + extra `tile_lay` slot
- [ ] **7.7** Minor F (White Peak): 33% discount on green terrain; +1 tile pt in green hexes **[L2]**
  *Implementation*: `tile_discount` (terrain: mountain) + extra `tile_lay` slot
- [ ] **7.8** Minor G (Indigo Foundry): +2 tile points per OR **[L2 `tile_lays`]**
  *Implementation*: custom `tile_lays` returning extra lay slots
- [ ] **7.9** Minor H (Great Western Steamship): reduces sea zones counted by 1 (Phase 1-6)
  or 2 (Phase 7-8) **[L2 custom route check]**
- [ ] **7.10** Minor J (Grey Locomotive Works): 10% discount on all train purchases **[L2]**
  *Implementation*: `train_discount` ability
- [ ] **7.11** Minor K (Vermilion Seal): mail contract pays revenue to treasury at OR start **[L2]**
  *Implementation*: `extra_revenue` hook or `hex_bonus`
- [ ] **7.12** Minor L (Krasnaya Strela): +1+1 marker adds 1 city limit and 1 town count
  to assigned train each OR; reassigned each OR **[L3]**
- [ ] **7.13** Minor M (CIWL): 10 Pullman cars (see §6) **[L3]**

---

## 8. Private Special Abilities — [L3]

**Status: descriptions only.** All 10 privates have rulebook `desc:` text in `entities.rb`.
Zero functional `abilities:` entries.

See `MD/ABILITIES_REFERENCE.md §2` for ability types needed for each private.

- [ ] **8.1** Wien Südbahnhof: free station token placement
  *Implementation*: `token` with `price: 0, when: 'token'`
- [ ] **8.2** Barclay, Bevan, Barclay & Tritton: three selectable options
  *Implementation*: `choose_ability` (3 options)
- [ ] **8.3** Star Harbor Trading Co.: port token in port city
  *Implementation*: `token` + custom `assign_hexes`
- [ ] **8.4** Central Circle Transport Corp.: token as town in non-port city
  *Implementation*: `token` + `hex_bonus`
- [ ] **8.5** White Cliffs Ferry: ferry crossing via Lille token at Phase 5
  *Implementation*: `tile_lay` + phase-trigger logic; uses `blocks_hexes_consent` on Lille (N31)
- [ ] **8.6** Hochberg Mining & Lumber: token in rough terrain; track restriction
  *Implementation*: `assign_hexes` + custom track restriction hook
- [ ] **8.7** Brandt & Brandau, Engineers: 4 tokens, 2/OR, free yellow tile; last token closes
  *Implementation*: `tile_lay` (free: true, count: 4, closed_when_used_up: true, when: 'track')
- [ ] **8.8** Swift Metropolitan Line: protects one 2+2 from train limit
  *Implementation*: custom game hook (no standard ability type)

---

## 9. Tile Definitions — Status and Gaps

**Confirmed tile point costs:** Yellow lay = 1pt / 2pt (metropolis);
Upgrade = 2pt / 4pt (metropolis).

**Confirmed double-town tile quantities:**
- Yellow double towns: qty 4, 6, 2 → **OE1, OE2, OE3** ✓
- Green double towns: qty 3, 3, 3 → OE9–OE11 commented out (orientations unknown)
- Brown double towns: qty 3, 2, 6 → OE20–OE22 commented out (orientations unknown)

**OE tile implementation state:**
- OE1–OE8: yellow ✓
- OE9–OE11: green double-towns — commented out (path edges unknown)
- OE12–OE18: green special city ✓
- OE19: **missing entirely** — tile type unknown
- OE20–OE22: brown double-towns — commented out
- OE23–OE33: brown special city ✓
- OE34–OE44: gray special city ✓

- [ ] **9.1** OE9–OE11: provide green double-town path edge orientations **[L1]**
- [ ] **9.2** OE20–OE22: provide brown double-town path edge orientations **[L1]**
- [ ] **9.3** OE19: identify tile type and define **[L1]**
- [ ] **9.4** Verify standard tile quantities against physical manifest **[L1]**
- [ ] **9.5** Audit all OE-specific tile upgrade paths against manifest **[L1]**

---

## 10. Route & Revenue Rules — [L2]

- [ ] **10.1** Cross-water costs: Ferry = +£5 track / +£20 token × distance;
  Sea = +£10 track / +£40 token × #sea zones
- [ ] **10.2** Ferry mechanics: distance counts against city limit; public ferry track;
  enemy tokens block public port city
- [ ] **10.3** Port authority markers: each reduces sea zone + ferry distance count by 2;
  16 total (8 North Sea, 8 Mediterranean)
- [ ] **10.4** Port types: public (any RR, anchor in light blue circle) vs private
  (anchor in red circle, restricted to token-owning RR)
- [ ] **10.5** Offshore port mechanics: train connects to city regardless of intervening hexes
- [ ] **10.6** Channel passages: adjacent sea zone indicators (Copenhagen, Constantinople)
- [ ] **10.7** Local train town counting: towns up to train level (additional = level; max = level)
- [ ] **10.8** Combined OE train runs: levels ≤4 combine; combined level = sum;
  city limit = combined level; towns = combined level

---

## 11. Consolidation Phase — [L3]

- [x] **11.1** Trigger — `or_set_finished` sets `@consolidation_triggered` when
  `@phase.name.to_i >= 5`; `next_round!` routes to `Round::G18OE::Consolidation` (once only)
- [~] **11.2** All remaining minors/regionals must merge or be abandoned —
  `Round::G18OE::Consolidation` scaffold exists; `Step::Consolidate` accepts only `pass` (TBD)
- [ ] **11.3** Cannot pass if owning unfloated minors/regionals *(enforcement deferred)*
- [ ] **11.4** Conditional merger: solicit offers from eligible majors/nationals; abandon
  if no offers *(deferred)*

---

## 12. Token Transfer Between Majors — [L2]

- [ ] **12.1** During major's Transfer Tokens step in OR: same player may transfer token
  between their two majors
- [ ] **12.2** Cost: token cost from charter (paying major) + token cost from receiving
  major's same zone + transfer fee (Normal City £20, Grand City £40, Metropolis £60)
- [ ] **12.3** Selling token: returns to charter at highest-cost open position

---

## 13. Minor Merger Rules — [L3]

- [ ] **13.1** Merge minor into national: national cannot inherit minor's special ability
  (except stock-type); minor abandoned after assets transferred
- [ ] **13.2** Cash transfer: minor's cash → major only if major has treasury stock; else forfeited
- [ ] **13.3** Stock exchange: minor owner gets 1 share from major's treasury (or Open Market);
  if neither, can only merge if hypothetical train connects minor's token to major's (or national's zone)
- [ ] **13.4** One merger per major/national per SR

---

## 14. End Game Rules — [L2]

- [ ] **14.1** Bank break before Level 8: finish current OR only
- [ ] **14.2** Level 8 available path: add remainder cash to bank; finish current OR; one SR; two final ORs
- [ ] **14.3** Final two ORs — second OR: each RR pays same revenue as first OR; no track/token/train
- [ ] **14.4** Win condition: highest (cash + stock at share value + face-up privates at face value)

---

## 15. Concession Railroad Phase (DEFERRED — Out of Scope)

Explicitly deferred and will NOT be implemented in the current development pass.

**What it involves:** After Auction Phase ends, 10 "Concession Railroad" float actions
occur in numbered order. Each concession holder pays 2× par to float their regional/major.

**Reason for deferring:** Requires a distinct round type and queue management that
significantly increases complexity without enabling playable testing of other mechanics.
Current implementation skips from Auction Phase to Regional/Minor Phase.

- [ ] **15.1** Define Concession round type with ordered float actions (CON1–CON10)
- [ ] **15.2** Concession cards: wire to specific regional/major home tokens and par values
- [ ] **15.3** Float obligation: concession holder pays 2× par; if unable, obligation transfers
- [ ] **15.4** Round sequencing: Auction → Concession → Regional/Minor Phase
- [ ] **15.5** 2-player without-concessions variant: skip concession phase (already in STARTING_CASH)

---

## 16. Tests

- [ ] **16.1** Basic game flow test (auction → regional/minor phase → major phase)
- [ ] **16.2** Train phase transition tests (rusting, limit changes, national formation trigger)
- [ ] **16.3** Stock market movement tests (right/left/up/down triggers, edge cases)
- [ ] **16.4** National revenue calculation test
- [ ] **16.5** Orient Express bonus test (first run, subsequent runs)
- [ ] **16.6** Minor ability transfer tests
- [ ] **16.7** Pullman car revenue test (nationals inherent Pullman)

---

## 17. Scenario / Variant Specifics

- [ ] **17.1** Confirm UK-FR variant entities match rulebook (4 minors: C, H, K, M;
  7 regionals: BEL, GSWR, GWR, LNWR, MIDI, OU, PLM)
- [ ] **17.2** UK-FR variant train rusting rules
- [ ] **17.3** Validate UK-FR map hex definitions against rulebook
- [ ] **17.4** Other scenarios (medium/short) — reduced RR counts, modified OE destinations

---

## 18. Temporary Workarounds

Active code workarounds that bypass correct behaviour for testing. Each tagged `WA-N`
in source. Remove/replace when prerequisite is met.

### WA-1 — National revenue: all zone nodes treated as linked *(PENDING)*

**Location**: `game.rb` — `national_revenue` *(method not yet written)*

Skip graph connectivity check for nationals. All cities/towns in zone counted as linked
regardless of track. **To remove**: fill in city revenues; verify `Graph.new(home_as_token:
true, no_blocking: true)` correctness; implement linked/unlinked node split.

---

### WA-3 — `respond_to?(:reclaim_train)` guard in train discard *(PENDING)*

**Location**: `game.rb` — `convert_to_national` *(not yet written)*

Guard against missing `Depot#reclaim_train` API. **To remove**: trigger national formation
with excess trains; if no crash and no manual deletion, remove the guard.

---

### WA-4 — `rescue` on `transfer_shares` in treasury-cert transfer *(PENDING)*

**Location**: `game.rb` — `convert_to_national` *(not yet written)*

Wrap `@share_pool.transfer_shares` in rescue for API signature mismatch.
**To remove**: trigger national formation; check game log for "WARN:" lines; if none,
remove rescue block; if found, fix the `transfer_shares` call.

---

### WA-5 — Silent `skip!` in `ConvertToNational` *(KEEP PERMANENTLY)*

**Location**: `step/convert_to_national.rb` *(file not yet written)*

`skip!` is a no-op when formation queue is empty. `process_pass` uses `current_entity`
(queue head) rather than `action.entity`. Correct behaviour for a conditional blocker.

---

_Last updated: 2026-04-22 — Reconciled openpoints.md against actual codebase and map.rb.
Enhanced 2026-04-23: added engine layer annotations, implementation notes from
ENGINE_MECHANICS.md and ABILITIES_REFERENCE.md._
