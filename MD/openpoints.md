# 18OE — Open Points

Tracked implementation gaps based on rulebook analysis (v1.0). Items are grouped by
area and roughly prioritized. Earlier items are more foundational.

**Engine layer annotations** (see `MD/ENGINE_MECHANICS.md` for explanation):
- **L1** = Layer 1: pure constants, no custom Ruby methods
- **L2** = Layer 2: named `Game::Base` method override
- **L3** = Layer 3: new step or round Ruby class required

---

## 1. Nationals

**Status 2026-04-22**: Data structures in place. No implementation code — `convert_to_national`,
`national_revenue`, `trigger_nationals_formation!` absent from game.rb; no
`step/convert_to_national.rb`.

- [x] **1.1** National corp type `:national` data — PHASES train limits, NATIONAL_REGION_HEXES
  all 8 zones, `NATIONAL_REGION_HEXES_COMPLETE = true` **[L1]**
- [ ] **1.2** National formation trigger — `Step::BuyTrain#process_buy_train` detects phase
  change to 4/6/8 and calls `game.trigger_nationals_formation!(buyer_player)`; players queued
  buyer-first **[L2]**
- [ ] **1.3** National formation steps in `convert_to_national` (game.rb): **[L2/L3]**
  - [ ] Major's cash → bank
  - [ ] All major treasury certs → Open Market
  - [ ] Remove all major tokens from map
  - [ ] Abandon merged minors *(deferred)*
  - [ ] Remove track rights, OE markers, private markers *(deferred)*
  - [ ] National operates in share-value sort bucket (same as majors)
  - [ ] National inherits all trains
- [ ] **1.4** National revenue calculation — `national_revenue` in game.rb: **[L2]**
  - [ ] Virtual tokens: `Graph.new(home_as_token: true, no_blocking: true)`
    (requires non-zero city revenues first)
  - [ ] Linked cities/towns at face value, best-first up to capacity
  - [ ] Remaining capacity: £60/city, £10/town
  - [ ] D trains doubling linked cities *(deferred)*
  - [ ] Must pay ALL revenue as dividends — `dividend_types` returns `[:payout]` only
- [ ] **1.5** Inherent Pullman bonus: +£10 × level of highest non-rusted train **[L2]**
- [ ] **1.6** Nationals cannot place tokens — `Token#actions` returns `[]` for nationals **[L2]**
- [ ] **1.7** Nationals exempt from terrain costs — `tile_cost_with_discount` returns 0 **[L2]**
- [ ] **1.8** `convert_to_national` must discard cheapest excess trains on formation **[L2]**
- [ ] **1.9** Nationals can claim rusted trains for free *(deferred)* **[L3]**
- [x] **1.10** `NATIONAL_REGION_HEXES` all 8 zones; `NATIONAL_REGION_HEXES_COMPLETE = true`;
  `CITY_NATIONAL_ZONE` overrides; `MINOR_EXCLUDED_HOME_CITIES` defined **[L1]**
- [x] **1.11** `@minor_available_regions` derived dynamically from regionals **[L2]**

---

## 2. Base Game Entities + Map

`g_18_oe/entities.rb` complete. `g_18_oe/map.rb` created and loadable; full terrain done;
651 blue hexes; 19 red offboards with best-guess revenues; 255 location names; city revenues TBD.

- [x] **2.1** Define all 24 regionals — home cities/coords, track rights zones **[L1]**
- [x] **2.2** Define all 12 minors — type `:minor`, tokens, shares, `desc:` ability text **[L1]**
- [x] **2.3** Define all 10 privates with face values, revenues, `desc:` ability text **[L1]**
- [x] **2.4** Minor-exchange auction cards for all 12 minors **[L1]**
- [x] **2.5** Define 10 concession cards CON1–CON10 *(concession phase deferred — §15)* **[L1]**
- [ ] **2.6** Logo artwork — grey circle stubs for 25 corporations:
  - Minors (8): A, B, D, E, F, G, J, L
  - Regionals (17): BHB, POB, KSS, KBS, SB; MAV, SFAI, SFR; CHN; MZA, RCP; MSP, MKV,
    LRZD; WW, DSJ, BJV
  - Already have real logos: LNWR, GWR, GSWR (UK); PLM, MIDI, OU, BEL (FR); minors C/H/K/M
- [~] **2.7** Base-game map `g_18_oe/map.rb`:
  - [x] Full grid coverage — 651 blue hexes
  - [x] 19 red off-board hexes implemented
  - [x] All terrain: UK/FR/Spain/Portugal/Scandinavia/Alps/Italy/Adriatic/Carpathians/
    Balkans/Caucasus/river crossings
  - [x] LOCATION_NAMES: 255 entries
  - [x] Pre-printed yellows (yellow section): Liverpool J25, Manchester J27, Athinai AE72,
    Amsterdam L37, Kobenhavn I50; I48 (Kattegat crossing) yellow track
  - [x] Station markers: all 255 named locations have `city=revenue:0` or `town=revenue:0`
  - [x] NATIONAL_REGION_HEXES all 8 zones; CITY_NATIONAL_ZONE overrides
  - [x] All on-board city revenues set to 0 — only ports will carry pre-printed revenues
    (ports not yet implemented)
  - [x] Pre-printed ferry paths added to white cities: N31 Lille (→1), M28 London (←5),
    AA82 Constantinople (→2), I20 Dublin (→4), O28 Le Havre (→1), X33 Marseille (→5)
  - [~] Ferry sea hexes — map data partially done (more routes outstanding):
    - N29 (English Channel, 4↔2), G22 (Irish Sea, 0↔4), N25 (0↔3)
    - I22 (1↔5 + 1↔4 branching), I24 (1↔5 + 1↔4 branching)
    - AE12 (3↔0), AF13 (2↔1)
    - AB21 (2↔4), AB23 (1↔4), AB25 (1↔4)
  - [~] Port hexes — partially done: AE6 (`town=revenue:20`, path 0↔3); more ports outstanding
  - [~] Lille↔London ferry (N31→N29→M28): open for playtesting (forced upgrade edges
    on both cities make tile placement work); all other ferry routes have map data but
    tiles cannot yet be placed to connect — blocked on engine override below
  - [ ] **Ferry route engine override** — tile placement validator rejects exits toward blue
    hexes by default. Need a Layer 2 override in `game.rb` (likely `check_tile_edges` or
    similar) to whitelist exits toward blue hexes that carry a matching pre-printed path.
    Covers two cases: (1) forced upgrade — city has pre-printed path facing ferry hex;
    (2) optional connection — player chooses to connect to ferry hex. Test with N31/M28
    first before assuming it works. **[L2]**
  - [~] Off-board revenues: 19 red hexes have best-guess revenues — need verification
  - [ ] Sea zone borders, distance numbers not encoded
  - [x] **Bug**: `NATIONAL_REGION_HEXES['SC']` contains `A40` — remove (now blue)
  - [x] **Bug**: `NATIONAL_REGION_HEXES['RU']` contains `E88` — remove (removed from map)

---

## 3. Train Mechanics (`step/buy_train.rb`) — [L2/L3]

Partially implemented (2026-04-12): depot level gating and inter-corp gate are in.
Obligation logic partly buggy. Insolvency and nationals-claim-rusted deferred.

- [x] **3.1** Reserved 2+2 obligation fully implemented **[L2]**:
  - `@fulfilled_train_obligation = Set.new` in `setup`; `attr_reader` on `game.rb`
  - `must_buy_train?` uses Set (not `entity.trains.empty?`) — one-time flag per entity
  - `buyable_trains`: during Regional/Minor Phase all entities restricted to level 2 trains
    (`!@game.major_phase?`); during Major Phase unfulfilled entities restricted to cheapest
    depot train (2+2 while available)
  - `process_buy_train`: snapshots phase status before `super`; marks entity fulfilled if
    purchase occurred in obligation window
- [ ] **3.2** Forced purchase — president covers shortfall; else national conversion (majors) or
  insolvency (minors/regionals) *(president contribution relies on base engine;
  national/insolvency deferred)* **[L3]**
- [ ] **3.3** First-round insolvency: president's cash → treasury; RR gets reserved 2+2;
  presidential cert → Open Market; president receives face value **[L3]**
- [x] **3.4** Obligation waived if Phase 4 starts before first OR — `must_buy_train?` uses
  `phase.status.include?('train_obligation')` (correct; no hard-coded phase integer) **[L2]**
- [x] **3.5** Depot level gating — `buyable_trains` filters to cheapest available level **[L2]**
- [x] **3.6** Inter-corp purchase gated to Phase 4+ — `can_buy_train_from_others?` **[L2]**
- [ ] **3.7** Nationals claim rusted trains for free *(deferred)* **[L3]**

---

## 4. Stock Market Movement — [L2]

- [x] **4.1** LEFT — zero dividend triggers `share_direction: :left`
- [x] **4.2** No movement — dividend > 0 but < share value returns `{}`
- [x] **4.3** UP — `sold_out_increase?` gates UP to `:major`/`:national` only;
  base engine `finish_round` → `sold_out_stock_movement` at SR end
- [ ] **4.4** +3 RIGHT — on first Orient Express run (in addition to dividend movement) **[L2]**

---

## 5. Orient Express Mechanic — [L2/L3]

- [ ] **5.1** Detect valid OE route: Constantinople + one of Paris/London/Berlin/Madrid/
  Sankt-Peterburg; must include land track **[L2 `check_other`]**
- [ ] **5.2** First-time bonus: £30 (Phase 2–4), £60 (Phase 5–6), £100 (Phase 7–8);
  bank → treasury; place OE marker on major **[L2 `revenue_for` + `action_processed`]**
- [ ] **5.3** Stock marker moves RIGHT×3 on first OE run **[L2]**
- [ ] **5.4** Train combining: levels ≤4 combine (sum); 5+/4D/5D cannot **[L2 `check_distance`]**
- [ ] **5.5** Subsequent OE runs: no bonus, no extra movement **[L2]**
- [ ] **5.6** Mandatory OE: if OE route is best possible, president must run it **[L2]**
- [ ] **5.7** OE blocked for nationals **[L2]**
- [ ] **5.8** D-train bonus does NOT apply to OE first-time bonus **[L2]**

---

## 6. Pullman Cars — [L3]

- [ ] **6.1** Pullman asset — doesn't count against train limit; max 1 per non-national **[L3]**
- [ ] **6.2** Revenue: +£10 × train level to one train per OR **[L2/L3]**
- [ ] **6.3** From Minor M: £150 (+ £15 royalty); J-minor discount on price not royalty **[L3]**
- [ ] **6.4** From Open Market: £150 no royalty; available Phase 4+ **[L3]**
- [ ] **6.5** From another RR: negotiated price **[L3]**
- [ ] **6.6** Nationals: inherent Pullman in `national_revenue` *(depends on §1.4)* **[L2]**
- [ ] **6.7** Minor M free Pullman at Phase 4 start if M not yet closed **[L2/L3]**
- [ ] **6.8** Discard rules — rusted trains first; Pullman voluntary discard **[L3]**
- [ ] **6.9** RR with zero trains + Pullman: Pullman stays until next train **[L3]**

---

## 7. Minor Special Abilities — [L3]

**Status: descriptions only.** All 12 minors have rulebook `desc:` text in `entities.rb`.
Zero functional `abilities:` entries. No transfer-on-merge mechanism.

See `MD/ABILITIES_REFERENCE.md §2` for ability types needed for each minor.

- [ ] **7.1** Ability transfer mechanism — minor merges with major; ability inherited;
  nationals cannot inherit abilities except stock-type **[L3]**
- [ ] **7.2** Minor A (Silver Banner): bank pays major = current share value on merge **[L3]**
- [ ] **7.3** Minor B (Orange Scroll): track upgrades cost 1 pt (not cities/grand/metro) **[L2]**
- [ ] **7.4** Minor C (Golden Bell): president chooses operating position each OR **[L3]**
- [ ] **7.5** Minor D (Green Junction): token in non-metro city; £20/£40 bonus by phase;
  removed at Phase 5 **[L3]**
- [ ] **7.6** Minor E (Blue Coast): 33% discount on water terrain; +1 pt in blue hexes **[L2]**
- [ ] **7.7** Minor F (White Peak): 33% discount on mountain terrain; +1 pt in green hexes **[L2]**
- [ ] **7.8** Minor G (Indigo Foundry): +2 tile points per OR **[L2]**
- [ ] **7.9** Minor H (Great Western Steamship): reduces sea zones counted by 1/2 by phase **[L2]**
- [ ] **7.10** Minor J (Grey Locomotive Works): 10% discount on train purchases **[L2]**
- [ ] **7.11** Minor K (Vermilion Seal): mail contract revenue to treasury at OR start **[L2]**
- [ ] **7.12** Minor L (Krasnaya Strela): +1+1 marker adds 1 city + 1 town to train each OR **[L3]**
- [ ] **7.13** Minor M (CIWL): 10 Pullman cars (see §6) **[L3]**

---

## 8. Private Special Abilities — [L3]

**Status: descriptions only.** All 10 privates have rulebook `desc:` text in `entities.rb`.
Zero functional `abilities:` entries.

See `MD/ABILITIES_REFERENCE.md §2` for ability types needed for each private.

- [ ] **8.1** Wien Südbahnhof: free station token placement (`token`, price: 0)
- [ ] **8.2** Barclay, Bevan, Barclay & Tritton: three selectable options (`choose_ability`)
- [ ] **8.3** Star Harbor Trading Co.: port token in port city (`token` + `assign_hexes`)
- [ ] **8.4** Central Circle Transport Corp.: token as town in city (`token` + `hex_bonus`)
- [ ] **8.5** White Cliffs Ferry: Lille (N31) token at Phase 5 (`tile_lay` + phase logic)
- [ ] **8.6** Hochberg Mining & Lumber: token in rough terrain; owner-only track (`assign_hexes`)
- [ ] **8.7** Brandt & Brandau: 4 tokens 2/OR, free yellow tile, closes on last token
  (`tile_lay`, free: true, count: 4, closed_when_used_up: true)
- [ ] **8.8** Swift Metropolitan Line: protects one 2+2 from train limit (custom hook)

---

## 9. Tile Definitions — Status and Gaps

- [x] **OE1–OE3**: yellow double-town tiles (3 orientations, qty 4/6/2) **[L1]**
- [x] **OE4–OE8**: yellow special city tiles **[L1]**
- [ ] **9.1** OE9–OE11: green double-town tiles (qty 3/3/3) — orientations unknown **[L1]**
- [x] **OE12–OE18**: green special city tiles **[L1]**
- [ ] **9.3** OE19: unknown tile type — not defined (gap between OE18 and OE20) **[L1]**
- [ ] **9.2** OE20–OE22: brown double-town tiles (qty 3/2/6) — orientations unknown **[L1]**
- [x] **OE23–OE33**: brown special city tiles **[L1]**
- [x] **OE34–OE44**: gray special city tiles **[L1]**
- [ ] **9.4** Verify standard tile quantities against physical manifest — `csv/tilemanifest.csv` created as reference export (tile, qty, color, label, description) **[L1]**
- [ ] **9.5** Audit all OE-specific tile upgrade paths against manifest **[L1]**

---

## 10. Route & Revenue Rules — [L2]

- [ ] **10.1** Cross-water costs: Ferry +£5 track / +£20 token × distance;
  Sea +£10 track / +£40 token × #sea zones
- [ ] **10.2** Ferry mechanics: distance counts against city limit; public ferry track;
  enemy tokens block public port city
- [ ] **10.3** Port authority markers: each reduces sea zone + ferry distance count by 2;
  16 total (8 North Sea, 8 Mediterranean)
- [ ] **10.4** Port types: public (any RR, light-blue anchor) vs private (red anchor)
- [ ] **10.5** Offshore port: train connects to city regardless of intervening hexes
- [ ] **10.6** Channel passages: adjacent sea zone indicators (Copenhagen, Constantinople)
- [ ] **10.7** Local train town counting: up to train level (max total = level)
- [ ] **10.8** Combined OE trains: levels ≤4 combine; combined level = sum

---

## 11. Consolidation Phase — [L3]

- [x] **11.1** Trigger — `event_consolidation_triggered!` at Phase 5; `next_round!` routes
  to Consolidation round (once only via `@consolidation_done`)
- [~] **11.2** Round scaffold — `Round::G18OE::Consolidation` + `Step::Consolidate` exists;
  `pass` only; merge/abandon actions TBD
- [ ] **11.3** Cannot pass if owning unfloated minors/regionals *(enforcement deferred)*
- [ ] **11.4** Conditional merger: solicit offers; player chooses; abandon if no offers *(deferred)*

---

## 12. Token Transfer Between Majors — [L2]

- [ ] **12.1** Same player may transfer token between their two majors during Token step
- [ ] **12.2** Cost: token cost (paying major) + token cost (receiving major, same zone) +
  transfer fee (Normal £20, Grand £40, Metropolis £60)
- [ ] **12.3** Selling token: returns to charter at highest-cost open position

---

## 13. Minor Merger Rules — [L3]

- [ ] **13.1** Merge into national: national cannot inherit minor's special ability (except stock-type)
- [ ] **13.2** Cash transfer: minor's cash → major only if treasury stock available; else forfeited
- [ ] **13.3** Stock exchange: minor owner gets 1 share from treasury (or Open Market); if neither,
  can only merge if track connects minor's token to major's (or national's zone)
- [ ] **13.4** One merger per major/national per SR

---

## 14. End Game Rules — [L2]

- [ ] **14.1** Bank break before Level 8: finish current OR only
- [ ] **14.2** Level 8 path: add remainder to bank; finish OR; one SR; two final ORs
- [ ] **14.3** Second final OR: each RR pays same revenue as first; no track/token/train actions
- [ ] **14.4** Win condition: cash + stock at share value + face-up privates at face value

---

## 15. Concession Railroad Phase (DEFERRED)

Explicitly deferred. Current implementation skips from Auction Phase to Regional/Minor Phase.

- [ ] **15.1** Concession round type with ordered float actions (CON1–CON10)
- [ ] **15.2** Wire concession cards to regional/major home tokens and par values
- [ ] **15.3** Float obligation: pays 2× par; obligation transfers if unable
- [ ] **15.4** Round sequencing: Auction → Concession → Regional/Minor Phase
- [ ] **15.5** 2-player without-concessions variant: skip concession phase

---

## 16. Tests

- [ ] **16.1** Basic game flow (auction → regional/minor → major phase)
- [ ] **16.2** Train phase transitions (rusting, limit changes, national formation trigger)
- [ ] **16.3** Stock market movement (right/left/up/down, edge cases)
- [ ] **16.4** National revenue calculation
- [ ] **16.5** Orient Express bonus (first run, subsequent runs)
- [ ] **16.6** Minor ability transfer
- [ ] **16.7** Pullman car revenue (nationals inherent Pullman)

---

## 17. Scenario / Variant Specifics

- [ ] **17.1** Confirm UK-FR variant entities (4 minors: C, H, K, M; 7 regionals: BEL, GSWR,
  GWR, LNWR, MIDI, OU, PLM)
- [ ] **17.2** UK-FR variant train rusting rules
- [ ] **17.3** Validate UK-FR map hex definitions
- [ ] **17.4** Other scenarios (medium/short) — reduced RR counts, modified OE destinations

---

## 18. Temporary Workarounds

Tagged `WA-N` in source. Remove/replace when prerequisite is met.

### WA-1 — National revenue: all zone nodes treated as linked *(PENDING)*

`game.rb` — `national_revenue` *(method not yet written)*. Skip graph connectivity for
nationals. **To remove**: fill city revenues; verify `Graph.new(home_as_token: true,
no_blocking: true)`; implement linked/unlinked node split.

### WA-3 — `respond_to?(:reclaim_train)` guard *(PENDING)*

`game.rb` — `convert_to_national` *(not yet written)*. Guard against missing
`Depot#reclaim_train`. **To remove**: trigger national formation with excess trains;
if no crash, remove guard.

### WA-4 — `rescue` on `transfer_shares` *(PENDING)*

`game.rb` — `convert_to_national` *(not yet written)*. Wrap `transfer_shares` in rescue
for API mismatch. **To remove**: trigger formation; check log for "WARN:" lines.

### WA-5 — Silent `skip!` in `ConvertToNational` *(KEEP PERMANENTLY)*

`step/convert_to_national.rb` *(not yet created)*. `skip!` no-ops when formation queue
is empty. `process_pass` uses `current_entity` (queue head). Correct permanent behaviour.

---

_Last updated: 2026-04-25 — §9.4 notes `csv/tilemanifest.csv` created as verification reference._
