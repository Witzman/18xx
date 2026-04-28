# 18OE — Open Points (with Rule Citations)

Modified copy of `openpoints.md`. Each open point is annotated with the authoritative
rulebook section and a key quote. Rule references are from **18OE Rulebook v1.0**.

**Engine layer annotations** (see `MD/ENGINE_MECHANICS.md` for explanation):
- **L1** = Layer 1: pure constants, no custom Ruby methods
- **L2** = Layer 2: named `Game::Base` method override
- **L3** = Layer 3: new step or round Ruby class required

---

## 1. Nationals

**Status 2026-04-29**: Core national formation fully implemented on branch `18oe_national`.
Remaining open items: 1.3c/1.3d deferred (depend on 18oe_mergers); 1.9b–1.9d deferred.

- [x] **1.1** National corp type `:national` data — PHASES train limits, NATIONAL_REGION_HEXES
  all 8 zones, `NATIONAL_REGION_HEXES_COMPLETE = true` **[L1]**
  > *§9.4 — "Nationals may only form when Train Phases 4, 6, and 8 begin … The share value marker of the major stays in the same place on the Stock Market and now represents the newly formed national."*

- [x] **1.2** National formation trigger — `Step::BuyTrain#process_buy_train` detects phase
  change to 4/6/8 and calls `game.trigger_nationals_formation!(buyer_player)`; players queued
  buyer-first **[L2]**
  > *§9.4 — "Nationals may only form when Train Phases 4, 6, and 8 begin at the moment of purchase of the first train of that Train Phase … Beginning with the player that purchased the train … proceeding in player order each player may convert one or more of their majors into nationals."*

- [~] **1.3** National formation steps in `convert_to_national` (game.rb): **[L2/L3]**
  > *§9.4 steps 1–5 — "A national is formed by completing all of the following steps."*
  - [x] Major's cash → bank
    > *§9.4 step 1 — "Place in the bank all cash in the treasury of the major that is forming the national."*
  - [x] All major treasury certs → Open Market
    > *§9.4 step 1 — "Place in the Open Market all certificates in the major's treasury and any Pullman it owns … This action may result in the temporary violation of the 50% Open Market limit."*
  - [x] Remove all major tokens from map
    > *§9.4 step 2 — "Remove from play all of the major's tokens that are on the Map."*
  - [ ] Abandon merged minors *(DEFERRED — depends on 18oe_mergers `@minor_track_rights`)*
    > *§9.4 step 3 — "Abandon any minors that have merged with the major (see 9.5)."*
  - [ ] Remove track rights, OE markers, private markers *(DEFERRED — same dependency)*
    > *§9.4 step 4 — "Remove from play all other assets on the major's charter except for trains. This includes track rights, port authorities, Orient Express markers, and private markers."*
  - [x] National operates in share-value sort bucket (same as majors) — `operating_order`
    > *§9.4 step 5 — "The share value marker of the major stays in the same place on the Stock Market and now represents the newly formed national."*
  - [x] National inherits all trains
    > *§9.4 step 5 — "A newly formed national retains all trains from the major, including rusted trains."*

- [x] **1.4** National revenue calculation — `national_revenue` in game.rb: **[L2]**
  > *§11.6.6 — Nationals use a zone-based virtual-token formula, not standard route running.*
  - [x] Zone hexes iterated; linked cities/towns at face value, best-first up to capacity
    > *Rulebook national charter — "A national's revenue equals the sum of all cities and towns in its home zone that its trains can reach."*
  - [x] Remaining capacity: £60/city, £10/town
    > *National charter rule — Unlinked capacity fills at £60/city, £10/town.*
  - [x] D trains double linked city revenue
    > *Train rules — D (diesel) trains double city revenue.*
  - [x] Must pay ALL revenue as dividends — `dividend_types` returns `[:payout]` only
    > *§11.4 — "Nationals must always pay dividends; they may not withhold or split revenue."*

- [x] **1.5** Inherent Pullman bonus: +£10 × level of highest non-rusted train **[L2]**
  > *§11.6.2 — "Every national owns the Pullman printed on its charter." National Pullman adds +£10 × highest non-rusted train level to revenue.*

- [x] **1.6** Nationals cannot place tokens — `Step::Token#actions` returns `[]` for nationals **[L2]**
  > *§9.4 — Nationals have no tokens remaining after formation (all removed in step 2); they operate via virtual tokens in their zone.*

- [x] **1.7** Nationals exempt from terrain costs — `tile_cost_with_discount` returns 0 **[L2]**
  > *§11.1.5 — "Nationals … pay no terrain costs when laying track."*

- [x] **1.8** `convert_to_national` discards cheapest excess trains via `@depot.reclaim_train` **[L2]**
  > *§9.4 / §11.6.6 — Train limits apply on formation; excess trains are discarded. "Developer's Note: if the Swift Metropolitan Line is one of the eliminated privates, the associated 2+2 train is not lost unless the train limit is exceeded."*

- [~] **1.9** Nationals and rusted trains (§11.6.6) **[L3]**
  > *§11.6.6 — "Nationals handle the buy trains step differently from all other RRs."*
  - [x] Claim unclaimed rusted trains from depot for free, up to train limit
    > *§11.6.6 — "First, the national may acquire unclaimed rusted trains for free, up to the national's train limit."*
  - [ ] Exchange owned rusted train for any higher-level unclaimed rusted train for free *(DEFERRED)*
    > *§11.6.6 — "Second, the national may … exchange one of their rusted trains for a higher level rusted train from the bank, for free."*
  - [ ] Flip owned rusted train from express side to local side for free *(DEFERRED)*
    > *§11.6.6 — National may flip an express-side rusted train to its local side for free.*
  - [ ] Upgrade rusted → non-rusted by purchasing from same-owner major; bank pays major ½ face value *(DEFERRED)*
    > *§11.6.6 — "Second, the national may upgrade one or more rusted trains to non-rusted trains by purchasing these trains from majors owned by the national's owner."*

- [x] **1.10** `NATIONAL_REGION_HEXES` all 8 zones; `NATIONAL_REGION_HEXES_COMPLETE = true`;
  `CITY_NATIONAL_ZONE` overrides; `MINOR_EXCLUDED_HOME_CITIES` defined **[L1]**
  > *§9.4 / Track Rights table (§9.1 Table 1) — 8 zones: UK, SC, FR, PHS, AH, IT, SP, RU.*

- [x] **1.11** `@minor_available_regions` — chit hash `{zone => count}` from `MINOR_TRACK_RIGHTS_CHITS`
  (2 chits per zone, 16 total); `@minor_asterisked_selected` counter; `claim_region!` decrements
  on home-token placement; asterisked-zone cap (UK/PHS/FR ≤ 4 combined) enforced **[L1/L2]**
  > *§9.1 Table 1 — "There are two track rights chits provided for each asterisked zone. When the fourth of the six chits is selected, the remaining track rights chits for these zones are removed from play."*

---

## 2. Base Game Entities + Map

- [x] **2.1** Define all 24 regionals — home cities/coords, track rights zones **[L1]**
  > *§9.2 / Table 1 — Each regional belongs to one track rights zone.*

- [x] **2.2** Define all 12 minors — type `:minor`, tokens, shares, `desc:` ability text **[L1]**
  > *§9.1 — Minors: single 100% certificate, par £120, auctioned in rows 7–12.*

- [x] **2.3** Define all 10 privates with face values, revenues, `desc:` ability text **[L1]**
  > *§6.1 — "Privates are purchased from the opening packet during the Auction RR Phase … A face up private pays its revenue to its owner at the beginning of each OR."*

- [x] **2.4** Minor-exchange auction cards for all 12 minors **[L1]**
  > *§7 Auction — Minor-exchange cards are rows 7–12 of the opening packet.*

- [x] **2.5** Define 10 concession cards CON1–CON10 *(concession phase deferred — §15)* **[L1]**
  > *§8.1 — "Train Phase 1 begins when the Auction RR Phase ends … coincides with the beginning of the Concession RR Phase."*

- [ ] **2.6** Logo artwork — grey circle stubs for 25 corporations *(visual only, no rule citation)*

- [~] **2.7** Base-game map `g_18_oe/map.rb`:
  - [x] Full grid coverage — 651 blue hexes
  - [x] 19 red off-board hexes implemented
  - [x] All terrain costs encoded
    > *§11.1.3 — "Yellow tiles may only be placed in the several shades of tan, reddish tan and olive green hexes … terrain costs apply to tile placement."*
  - [x] Pre-printed yellows and station markers
  - [x] Pre-printed ferry paths on white cities
    > *§11.3.7 — "There are many ferries in 18OE, each represented by blue track crossing sea zones."*
  - [~] Ferry sea hexes — map data partially done
    > *§11.3.7 — "A train rides a ferry by using a track section that connects the town or city with the ferry's blue track in the adjacent sea zone. Ferries have an oval containing a number next to them. This number is the ferry's distance."*
  - [~] Port hexes — partially done
    > *§11.3.4 — Port tokens reduce sea zone counts for train routes.*
  - [ ] **Ferry route engine override** — tile placement validator rejects exits toward blue hexes **[L2]**
    > *§11.3.7 — Ferry connections are pre-printed; tile upgrade must preserve the ferry exit edge.*
  - [~] Off-board revenues: best-guess, need verification
    > *Physical map — off-board revenues printed as phase-graduated values.*
  - [ ] Sea zone borders, distance numbers not encoded
    > *§11.3.4 — "A port authority marker will reduce by two the total number of sea zones that count against trains' city limits within its jurisdiction."*

---

## 3. Train Mechanics (`step/buy_train.rb`) — [L2/L3]

- [x] **3.1** Reserved 2+2 obligation + general must-buy rule **[L2]**
  > *§11.6.1 — "One 2+2 train is reserved for each regional, minor, and major in the game. Each regional, minor, and major must purchase one of these trains from the Locomotive Works with its starting capital during its turn in the first OR after it floats. This obligatory purchase must be made before any other train purchases."*
  > *§11.6 — "Every major must own at least one train at the end of its OR."*
  > *§11.6.5 (end) — "Minors and regionals are not required to own a train."*

- [ ] **3.2** Forced purchase — president covers shortfall; else national conversion (majors) or insolvency (minors/regionals) **[L3]**
  > *§11.6.4 — "When a major must force buy a train, it will always purchase the lowest cost, un-rusted train available … If the major does not have sufficient funds in its treasury, the president must contribute the difference from personal cash."*
  > *§11.6.5 — "If the president of a minor or regional does not have sufficient personal cash … the first-round insolvency procedure applies."*

- [ ] **3.3** First-round insolvency: president's cash → treasury; RR gets reserved 2+2; presidential cert → Open Market; president receives face value **[L3]**
  > *§11.6.5 — "President's cash is transferred to the RR's treasury. The RR receives its reserved 2+2 train. The presidential certificate is placed in the Open Market. The president receives an amount equal to the face value of the presidential certificate from the bank."*

- [x] **3.4** Obligation waived if Phase 4 starts before first OR **[L2]**
  > *§11.6.1 — The 2+2 obligation only applies during Train Phases 1–3 when `train_obligation` status is active.*

- [x] **3.5** Depot level gating — `buyable_trains` filters to cheapest available level **[L2]**
  > *§11.6 — Trains are purchased from the Locomotive Works (depot) in level order; higher levels are not available until lower levels are exhausted.*

- [x] **3.6** Inter-corp purchase gated to Phase 4+ **[L2]**
  > *§11.6 — "Starting at Train Phase 4 a RR may purchase a train from another RR."*

- [ ] **3.7** Nationals claim rusted trains for free *(deferred — handled in §1.9)* **[L3]**
  > *§11.6.6 — "First, the national may acquire unclaimed rusted trains for free, up to the national's train limit."*

---

## 4. Stock Market Movement — [L2]

> *§4.4 — "The value of shares in a RR usually changes when players buy or sell shares, when its shares are sold out, and when the RR pays or withholds dividends."*

- [x] **4.1** LEFT — zero dividend
  > *§4.4 — "LEFT: The marker moves one square to the left … [when] the RR withholds all revenue (pays £0 dividend)."*

- [x] **4.2** No movement — dividend > 0 but < share value
  > *§4.4 — No movement when dividend is positive but less than share price, or when marker is at £550.*

- [x] **4.3** UP — `sold_out_increase?` gates to `:major`/`:national` only
  > *§10.7 — "At the end of a SR the share value marker of any major or national which has all shares in players hands will move UP on the Stock Market."*

- [ ] **4.4** +3 RIGHT — on first Orient Express run **[L2]**
  > *§12.2 — "The first time that a given major runs the Orient Express … the stock price of the major moves RIGHT 3 times."*

- [ ] **4.5** §9.3 post-conversion sell window — player may sell other RR shares after conversion, before mandatory president buy **[L2]**
  > *§9.3 step 4 — "Optional — the active player may sell any number of shares of any RR they already own … This player may not sell shares of the newly floated major."*

---

## 5. Orient Express Mechanic — [L2/L3]

> *§12 — "Only majors may make an Orient Express run. A train whose route includes Constantinople and one or more of the metropolises of Paris, London, Berlin, Madrid, or Sankt-Peterburg has operated The Orient Express."*

- [ ] **5.1** Detect valid OE route: Constantinople + one of Paris/London/Berlin/Madrid/Sankt-Peterburg; must include land track **[L2 `check_other`]**
  > *§12 — Route requirement: Constantinople + at least one of the five named metropolises; the route must use some land track (cannot be entirely sea).*

- [ ] **5.2** First-time bonus: £30 (Phase 2–4), £60 (Phase 5–6), £100 (Phase 7–8); bank → treasury; place OE marker **[L2]**
  > *§12.2 — "The first time that a given major runs the Orient Express during the game, the major is given an Orient Express marker. The president of the major may then choose one of the following bonuses …" Bonus amounts: £30 (Phases 2–4), £60 (Phases 5–6), £100 (Phases 7–8).*

- [ ] **5.3** Stock marker moves RIGHT×3 on first OE run **[L2]**
  > *§12.2 — "… the stock price of the major moves RIGHT 3 times."*

- [ ] **5.4** Train combining: levels ≤4 combine (sum); 5+/4D/5D cannot **[L2 `check_distance`]**
  > *§12.1 — "For the purpose of making an Orient Express run, a major may combine two or more non-permanent trains into one larger train (i.e., level 2, 3, and 4 trains may be combined)."*

- [ ] **5.5** Subsequent OE runs: no bonus, no extra movement **[L2]**
  > *§12.2 — The OE marker is placed on the first run; subsequent runs receive no bonus and no extra stock movement.*

- [ ] **5.6** Mandatory OE: if OE route is best possible, president must run it **[L2]**
  > *§12 — "If the Orient Express route produces the highest possible revenue, the president must run it."*

- [ ] **5.7** OE blocked for nationals **[L2]**
  > *§12 — "Only majors may make an Orient Express run."*

- [ ] **5.8** D-train bonus does NOT apply to OE first-time bonus **[L2]**
  > *§12.2 — The OE first-time bonus is a fixed amount added to the treasury; D-train revenue doubling does not apply to it.*

---

## 6. Pullman Cars — [L3]

> *§11.6.2 — "After the beginning of Train Phase 4 a RR may purchase a Pullman car from Minor M during its buy train step … A RR may own at most one Pullman … A Pullman does not count against a RR's train limit."*

- [ ] **6.1** Pullman asset — doesn't count against train limit; max 1 per non-national **[L3]**
  > *§11.6.2 — "A RR may own at most one Pullman … A Pullman does not count against a RR's train limit."*

- [ ] **6.2** Revenue: +£10 × train level to one train per OR **[L2/L3]**
  > *§11.6.2 — "A Pullman adds +£10 per train level to the revenue of one train per OR."*

- [ ] **6.3** From Minor M: £150 (+ £15 royalty); J-minor discount on price not royalty **[L3]**
  > *§11.6.2 — "A RR may purchase a Pullman car from Minor M … for £150 plus a £15 royalty paid to Minor M's owner." Minor J discount applies to the purchase price only, not the royalty.*

- [ ] **6.4** From Open Market: £150 no royalty; available Phase 4+ **[L3]**
  > *§11.6.2 — "After Minor M has closed, a RR may purchase a Pullman from the Open Market for £150 with no royalty."*

- [ ] **6.5** From another RR: negotiated price **[L3]**
  > *§11.6.2 — A Pullman may be transferred between RRs at a negotiated price during the buy trains step.*

- [ ] **6.6** Nationals: inherent Pullman in `national_revenue` *(implemented in §1.5)* **[L2]**
  > *§9.4 step 1 — "every national owns the Pullman printed on its charter."*

- [ ] **6.7** Minor M free Pullman at Phase 4 start if M not yet closed **[L2/L3]**
  > *§11.6.2 — Minor M receives one free Pullman at the beginning of Train Phase 4 if it has not yet closed.*

- [ ] **6.8** Discard rules — rusted trains first; Pullman voluntary discard **[L3]**
  > *§11.6.2 — "A RR may discard a Pullman during its buy train step prior to buying trains." Rusted trains are discarded before the Pullman when over limit.*

- [ ] **6.9** RR with zero trains + Pullman: Pullman stays until next train **[L3]**
  > *§11.6.2 — A Pullman is retained even when the owning RR has no trains; it becomes active again when the RR acquires a train.*

---

## 7. Minor Special Abilities — [L3]

**Status: descriptions only.** Abilities are defined on the individual minor charters
(Playbook §15 / physical charter cards). Each ability transfers to the absorbing major on merger.

> *§10.5 — "Each minor has a special ability that will be acquired by the major it merges into … A national may not acquire any special ability from a minor except for stock-type special abilities."*

- [ ] **7.1** Ability transfer mechanism — minor merges with major; ability inherited;
  nationals cannot inherit abilities except stock-type **[L3]**
  > *§10.5 — "Each minor has a special ability that will be acquired by the major it merges into … A national may not acquire any special ability from a minor except for stock-type special abilities."*

- [ ] **7.2** Minor A (Silver Banner): bank pays major = current share value on merge **[L3]**
  > *Minor A charter — On merge, the bank pays the absorbing major an amount equal to the major's current share value.*

- [ ] **7.3** Minor B (Orange Scroll): track upgrades cost 1 pt (not cities/grand/metro) **[L2]**
  > *Minor B charter — Track upgrades (green/brown/gray, excluding city/grand/metropolis tiles) cost 1 tile point instead of 2.*

- [ ] **7.4** Minor C (Golden Bell): president chooses operating position each OR **[L3]**
  > *Minor C charter — The owning major's president may choose where in operating order the major acts each OR.*

- [ ] **7.5** Minor D (Green Junction): token in non-metro city; £20/£40 bonus by phase; removed at Phase 5 **[L3]**
  > *Minor D charter — Places a token in a non-metropolis city granting a revenue bonus (£20 Phases 2–4, £40 Phases 5+); token is removed at Phase 5 start.*

- [ ] **7.6** Minor E (Blue Coast): 33% discount on water terrain; +1 pt in blue hexes **[L2]**
  > *Minor E charter — 33% discount on water-terrain tile costs; grants +1 tile point when laying track in sea-adjacent (blue) hexes.*

- [ ] **7.7** Minor F (White Peak): 33% discount on mountain terrain; +1 pt in green hexes **[L2]**
  > *Minor F charter — 33% discount on mountain-terrain tile costs; grants +1 tile point in green-tiled hexes.*

- [ ] **7.8** Minor G (Indigo Foundry): +2 tile points per OR **[L2]**
  > *Minor G charter — The owning RR gains +2 tile points per OR.*

- [ ] **7.9** Minor H (Great Western Steamship): reduces sea zones counted by 1 (Phases 2–6) or 2 (Phases 7–8) **[L2]**
  > *Minor H charter / §11.3.4 — Acts as a port token: reduces the number of sea zones counted against train city limits by 1 in Phases 2–6, by 2 in Phases 7–8.*

- [ ] **7.10** Minor J (Grey Locomotive Works): 10% discount on train purchases **[L2]**
  > *Minor J charter — Owning RR pays 10% less when purchasing trains from the depot or other RRs.*

- [ ] **7.11** Minor K (Vermilion Seal): mail contract revenue to treasury at OR start **[L2]**
  > *Minor K charter — At the beginning of each OR, the owning RR receives a fixed mail contract payment into its treasury (amount phase-dependent).*

- [ ] **7.12** Minor L (Krasnaya Strela): +1+1 marker adds 1 city + 1 town to one train each OR **[L3]**
  > *Minor L charter — Places a +1+1 marker that increases one train's effective city capacity by 1 and town capacity by 1 each OR.*

- [ ] **7.13** Minor M (CIWL): 10 Pullman cars (see §6) **[L3]**
  > *Minor M charter / §11.6.2 — "A RR may purchase a Pullman car from Minor M … Minor M starts with 10 Pullman cars."*

---

## 8. Private Special Abilities — [L3]

**Status: descriptions only.** All 10 privates have `desc:` text. See rulebook §14 for full text.

> *§6.1 — "Privates are purchased from the opening packet during the Auction RR Phase … A face up private pays its revenue to its owner at the beginning of each OR."*

- [ ] **8.1** Wien Südbahnhof: free station token placement (`token`, price: 0)
  > *§14.3 — "During any RR's place token step, the owner of this private may place any one of the RR's station tokens on the Map for free … The token must be reachable by the given RR using the same rules as if it were paying for the token."*

- [ ] **8.2** Barclay, Bevan, Barclay & Tritton: three selectable options (`choose_ability`)
  > *§14.4 — Three one-time options: (1) reset the par value marker of an owned regional/major; (2) place a share of a RR into custodianship/reservation; (3) prevent one RR's share value from moving DOWN for the remainder of the current SR.*

- [ ] **8.3** Star Harbor Trading Co.: port token in port city (`token` + `assign_hexes`)
  > *§14.5 — "Token allows free passage through port cities; affiliated RR may use token as private or public port during sea crossing." Confers §11.3.4 port-authority benefits.*

- [ ] **8.4** Central Circle Transport Corp.: token as town in city (`token` + `hex_bonus`)
  > *§14.6 — Token counts as a town when a route runs through the city; adds revenue equal to the town value for that phase (£10/£20/£40/£60 by phase).*

- [ ] **8.5** White Cliffs Ferry: Lille (N31) token at Phase 5 (`tile_lay` + phase logic)
  > *§14.7 — "At the beginning of Train Phase 5, the player who owns this private may immediately place one station token from any controlled RR on top of the White Cliffs Ferry token position next to the city of Lille."*

- [ ] **8.6** Hochberg Mining & Lumber: token in rough terrain; owner-only track (`assign_hexes`)
  > *§14 — Places a token in a rough-terrain hex; only the owning major may lay track through that hex.*

- [ ] **8.7** Brandt & Brandau: 4 tokens 2/OR, free yellow tile, closes on last token
  > *§14 — Owner may use 2 tokens per OR (4 total) to place free yellow tiles; private closes when last token is used. Engine: `tile_lay`, `free: true`, `count: 4`, `closed_when_used_up: true`.*

- [ ] **8.8** Swift Metropolitan Line: protects one 2+2 from train limit
  > *§9.4 Developer's Note — "if the Swift Metropolitan Line is one of the eliminated privates, the associated 2+2 train is not lost unless the train limit is exceeded."*

---

## 9. Tile Definitions — Status and Gaps

> *§11.1.3 — Tile colour progression: yellow → green → brown → gray.*

- [ ] **9.1** OE9–OE11: green double-town tiles (qty 3/3/3) — orientations unknown **[L1]**
  > *Physical tile manifest — OE9/OE10/OE11 exist on the physical tile sheet; path orientations must be read from the physical tiles or manifest.*

- [ ] **9.2** OE20–OE22: brown double-town tiles (qty 3/2/6) — orientations unknown **[L1]**
  > *Physical tile manifest — same as above for brown variants.*

- [ ] **9.3** OE19: unknown tile type — not defined (gap between OE18 and OE20) **[L1]**
  > *Physical tile manifest — OE19 is listed in the manifest but its type is unconfirmed; may be a special track or off-map connector.*

- [ ] **9.4** Verify standard tile quantities against physical manifest **[L1]**
  > *Physical tile manifest (`csv/tilemanifest.csv`) — quantities must match the physical tile count from the game box.*

- [ ] **9.5** Audit OE-specific tile upgrade paths **[L1]**
  > *§11.1.3 — Each tile must correctly list its legal upgrades; upgrade paths must match the physical tile backs.*

---

## 10. Route & Revenue Rules — [L2]

> *§11.3 — "Each train may make one run … A train's route is a continuous path of track …"*

- [ ] **10.1** Cross-water costs: Ferry +£5 track / +£20 token × distance; Sea +£10 track / +£40 token × #sea zones
  > *§11.3.7 — "Ferries have an oval containing a number next to them. This number is the ferry's distance. When the train rides the ferry this number counts towards the train's city limit." Track cost: +£5 per ferry distance unit; token cost: +£20 per ferry distance unit. Sea zones: +£10 per zone for track, +£40 per zone for tokens.*

- [ ] **10.2** Ferry mechanics: distance counts against city limit; public ferry track; enemy tokens block public port city
  > *§11.3.7 — "A train rides a ferry by using a track section that connects the town or city with the ferry's blue track in the adjacent sea zone … the ferry's distance counts towards the train's city limit." Enemy tokens in a public port city block use of that port.*

- [ ] **10.3** Port authority markers: each reduces sea zone + ferry distance count by 2; 16 total (8 North Sea, 8 Mediterranean)
  > *§11.3.4 — "A port authority marker will reduce by two the total number of sea zones that count against trains' city limits within its jurisdiction … majors may purchase a port authority marker from another major … The price paid must be exactly £125."*

- [ ] **10.4** Port types: public (any RR, light-blue anchor) vs private (red anchor)
  > *§11.3.4 — Public port cities (light-blue anchor) may be used by any RR; private port cities (red anchor) may only be used by the owning RR or the Star Harbor Trading Company.*

- [ ] **10.5** Offshore port: train connects to city regardless of intervening hexes
  > *§11.3.4 — Offshore ports allow a train to connect to a city without traversing intervening land hexes, subject to sea-zone crossing costs.*

- [ ] **10.6** Channel passages: adjacent sea zone indicators (Copenhagen, Constantinople)
  > *Map notation — Channel passages at Copenhagen (Kattegat) and Constantinople (Bosphorus) allow adjacent sea zones to be treated as connected with reduced crossing cost.*

- [ ] **10.7** Local train town counting: up to train level (max total = level)
  > *§11.3 — Local trains count towns up to their train level; combined city + town count cannot exceed the train level.*

- [ ] **10.8** Combined OE trains: levels ≤4 combine; combined level = sum
  > *§12.1 — "For the purpose of making an Orient Express run, a major may combine two or more non-permanent trains into one larger train (i.e., level 2, 3, and 4 trains may be combined)." Combined level = sum of individual levels.*

---

## 11. Consolidation Phase — [L3]

> *§10.6 — "During the Consolidation RR Phase (which is the first SR after the beginning of Train Phase 5) all remaining minors and regionals will be consolidated into majors and/or nationals."*

- [x] **11.1** Trigger — `event_consolidation_triggered!` at Phase 5
  > *§10.6 — Consolidation RR Phase is the first SR after the beginning of Train Phase 5.*

- [~] **11.2** Round scaffold — `Round::G18OE::Consolidation` + `Step::Consolidate` exists; `pass` only
  > *§10.6 — Each player must merge or abandon all owned minors and regionals before they may pass.*

- [ ] **11.3** Cannot pass if owning unfloated minors/regionals
  > *§10.6 — "If a player owns a major that has not yet floated, the player may not select the pass option during the SR until the major has floated."*

- [ ] **11.4** Conditional merger: solicit offers; player chooses; abandon if no offers
  > *§10.6 — Player with an unmergeable minor must publicly solicit offers; if one offer they must accept; if multiple they choose; if none the minor is abandoned.*

---

## 12. Token Transfer Between Majors — [L2]

> *§11.2 — "During the transfer tokens step, a major may transfer one or more of its station tokens to another major owned by the same player."*

- [ ] **12.1** Same player may transfer token between their two majors during Token step
  > *§11.2 — Transfer allowed during the owning RR's token step; both majors must be owned by the same player.*

- [ ] **12.2** Cost: token cost (paying major) + token cost (receiving major, same zone) + transfer fee (Normal £20, Grand £40, Metropolis £60)
  > *§11.2 — Transfer fee varies by city type: Normal city £20, Grand city £40, Metropolis £60. The paying major covers the full cost.*

- [ ] **12.3** Selling token: returns to charter at highest-cost open position
  > *§11.2 — When a token is removed from the map (e.g., on national formation), it returns to the charter's highest-cost unfilled token slot.*

---

## 13. Minor Track Rights & Merger (§10.5) — [L2/L3]

**Status 2026-04-28**: Track-rights chit system live. §10.5 merger SR action implemented in
branch `18oe_mergers`. §13B–13D and §13.25–13.26 done. §13E items deferred.

> *§10.5 — "Starting at the beginning of Train Phase 3 a minor may merge into a major or national during a SR. Each minor has a special ability that will be acquired by the major it merges into … a given major or national may only merge with a single minor in any given SR."*

### 13A — Track-rights chit system (done)

- [x] **13.1** `MINOR_TRACK_RIGHTS_CHITS {zone => 2}`: 8 zones × 2 chits = 16 total **[L1]**
  > *§9.1 Table 1 — Two chits per zone, 16 total for 12 minors.*

- [x] **13.2** Asterisked zone cap (UK/PHS/FR ≤ 4 combined) **[L1]**
  > *§9.1 — "When the fourth of the six chits is selected, the remaining track rights chits for these zones are removed from play."*

- [x] **13.3–13.6** Setup, availability, and major_phase? gate **[L1/L2]**
  > *§9.1, §9.2 — Track rights chit selection and zone availability enforced at home token placement.*

### 13B–13D — §10.5 merger action (done in 18oe_mergers)

- [x] **13.7–13.19** Engine plumbing, BuySellParShares additions, merge_minor! sub-steps
  > *§10.5 — Full minor merger procedure: share exchange, cash transfer, token transfer, train transfer, track rights transfer, close minor.*

### 13E — Deferred

- [ ] **13.20** No-stock hypothetical connection check **[L3]**
  > *§10.5 — "If no stock is available … the minor may only merge if an unlimited-city-limit train can reach from the minor's token to the major's token."*

- [ ] **13.21** Player choice on token decline **[L3]**
  > *§10.5 — When a minor's token conflicts with an existing major token in the same city, the major's president chooses which token to keep.*

- [ ] **13.22** Player choice on train decline **[L3]**
  > *§10.5 — Major may decline specific trains from the minor if accepting would exceed its train limit.*

- [ ] **13.23** Cross-player personal cash payment **[L3]**
  > *§10.5 — "A player may make a personal cash payment to another player as part of a minor merger negotiation. RR treasury cash may not be used."*

- [ ] **13.24** Solicit-offers rule **[L3]**
  > *§10.5 — Player with an unmergeable minor must publicly request offers; one offer → must accept; multiple → player chooses; none → minor abandoned.*

- [x] **13.25** Nationals: no tokens, no special ability, no track rights; cash forfeited to bank
  > *§10.5 — "A national may not acquire any special ability from a minor except for stock-type special abilities."*

- [x] **13.26** Track rights terrain discount (20% for IT/SP/RU/SC zones)
  > *§11.1.5 — "RRs who have track rights in certain zones get a track building discount inside their zone."*

- [ ] **13.27** Consolidation Round forced mergers **[L3]**
  > *§10.6 — Same §10.5 merger rules apply during the Consolidation RR Phase, but participation is mandatory.*

---

## 14. End Game Rules — [L2]

> *§13 — "The game ends in one of two ways …"*

- [ ] **14.1** Bank break before Level 8: finish current OR only
  > *§13 — "If the bank runs out of money during an OR prior to the purchase of the first level 8 train, finish only the current OR."*

- [ ] **14.2** Level 8 path: add remainder to bank; finish OR; one SR; two final ORs
  > *§13 — "If the bank does not run out of money prior to the purchase of the first level 8 train, add all the 'remainder cash' to the bank at the moment of purchase. Finish the current OR, then play one SR followed by two final ORs."*

- [ ] **14.3** Second final OR: each RR pays same revenue as first; no track/token/train actions
  > *§13 — In the second final OR, each RR automatically pays the same dividend as in the first final OR. No tile, token, or train actions are taken.*

- [ ] **14.4** Win condition: cash + stock at share value + face-up privates at face value
  > *§13.1 — "The winner is the player with the highest combined total of cash, stock certificates at share value, and face up privates at face value."*

---

## 15. Concession Railroad Phase (DEFERRED)

> *§8 — "Train Phase 1 begins when the Auction RR Phase ends … coincides with the beginning of the Concession RR Phase. Train Phase 1 starts with the player holding the 1st concession …"*

- [ ] **15.1** Concession round type with ordered float actions (CON1–CON10)
  > *§8.1 — "10 concessions provide the right to take stock actions … in numbered order."*

- [ ] **15.2** Wire concession cards to regional/major home tokens and par values
  > *§8 — Each concession card designates a specific regional and provides a starting par value.*

- [ ] **15.3** Float obligation: pays 2× par; obligation transfers if unable
  > *§9.2 / §8 — "The player pays cash to the regional's treasury equal to twice the chosen par value." If unable, the obligation transfers to the next concession holder.*

- [ ] **15.4** Round sequencing: Auction → Concession → Regional/Minor Phase
  > *§7, §8 — Game sequence: Auction RR Phase → Train Phase 1 / Concession RR Phase → Regional/Minor RR Phase.*

- [ ] **15.5** 2-player without-concessions variant: skip concession phase
  > *Playbook §5.4 — 2-player game uses the without-concessions formula and skips the Concession RR Phase.*

---

## 16. Tests

- [ ] **16.1** Basic game flow (auction → regional/minor → major phase)
  > *§7–§9 — Full startup sequence.*

- [ ] **16.2** Train phase transitions (rusting, limit changes, national formation trigger)
  > *§11.6 / §9.4 — Phase 4/6/8 train purchases trigger rusting and national formation.*

- [ ] **16.3** Stock market movement (right/left/up/down, edge cases)
  > *§4.4 / §10.7.*

- [ ] **16.4** National revenue calculation
  > *§11.6.6 / §1.4.*

- [ ] **16.5** Orient Express bonus (first run, subsequent runs)
  > *§12.*

- [ ] **16.6** Minor ability transfer
  > *§10.5.*

- [ ] **16.7** Pullman car revenue (nationals inherent Pullman)
  > *§11.6.2 / §9.4.*

---

## 17. Scenario / Variant Specifics

- [ ] **17.1–17.4** UK-FR variant and other scenarios
  > *Playbook — UK-FR uses 4 minors (C, H, K, M) and 7 regionals (BEL, GSWR, GWR, LNWR, MIDI, OU, PLM); see Playbook §5 for variant rules.*

---

## 18. Temporary Workarounds

### WA-1 — National revenue: all zone nodes treated as linked *(PENDING)*
> *§11.6.6 — Correct implementation requires confirmed city revenues and graph connectivity. Until revenues are filled, all zone nodes treated as linked.*

### WA-3 — `respond_to?(:reclaim_train)` guard *(REMOVED in 18oe_national)*
> *Engine — `Depot#reclaim_train` confirmed present; guard removed.*

### WA-4 — `rescue` on `transfer_shares` *(REMOVED in 18oe_national)*
> *Engine — `SharePool#transfer_shares` API confirmed; rescue removed.*

### WA-5 — Silent `skip!` in `ConvertToNational` *(KEEP PERMANENTLY)*
> *§9.4 — `skip!` no-ops when formation queue is empty. Correct permanent behaviour.*

---

## 19. Upstream Engine Requests

### 19.1 — Province partition rendering *(PENDING UPSTREAM)*

> *Map — Province-style (orange dashed) corner-to-corner lines needed for national zone boundaries crossing a hex.*

**Problem**: `assets/app/view/game/part/partitions.rb` does not handle `type:province`.

**Fix** (from reviewer): Extend `Partitions` with `:province` color branch, `partition_dash` helper,
and update skip guard to `!%i[divider province].include?(partition.type)`.

---

*Last updated: 2026-04-29 — Full rule citations added. Rule sections from 18OE Rulebook v1.0.
Minor special abilities cited from charter cards (Playbook §15); exact text on physical charters.*
