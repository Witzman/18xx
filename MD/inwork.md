# 18OE — In Work

Items currently in flight: `[~]` in development · `[t]` implemented, testing in progress · `[>]` all tests passed, needs PR.

Move items here from `MD/todo.md` at session start. Move to `MD/done.md` when complete + PR merged.

Layers: L1 constants · L2 Game::Base override · L3 new Step/Round file
Branch tag: backtick-wrapped branch name at end of each item line; `?` = branch not yet recorded

Items without a milestone tag = **alpha**. `[BETA]` = deferred to beta milestone.

---

## D-Train Revenue (BUG-031)
- [>] D-train city revenue doubling — 4D/5D trains double city value; then suppress doubling for Krasnaya Strela extra city (§15.7) **[alpha]** **[L2]** `18oe_testing`

## Minor Abilities
- [>] J – Grey Locomotive **[alpha]** **[L1]** `18oe_testing`
- [>] **C** (Golden Bell) — pre-OR blocking choice step (GoldenBellChoice); `first`/`last`/`normal`; entity order rebuilt from `operating_order` after choice **[alpha]** **[L3]** `18oe_testing`
- [t] **D** (Green Junction) — DTokenPlacement step; assign action during track window; any non-metro non-offboard city; Phase 5 transition already wired **[alpha]** **[L3]** `18oe_testing`
- [t] **L** (Krasnaya Strela) — KrasnayaStrelaAssign step wired; train-choice before Route step; D-train doubling exception in `18oe_dtrain_doubling` (BUG-031) **[alpha]** **[L3]** `18oe_testing`

## Private Abilities
- [t] **Central Circle** — hex_bonus approximation (£10/£20/£40/£60 by phase via after_phase_change); SR window via extra_action:true already wired; city-as-town routing deferred to beta (BUG-032) **[alpha]** **[L2]** `18oe_testing`
- [t] **Hochberg Mining** — HochbergPlacement step (rough terrain ≥ £45); routing exclusion via check_route_token override; removal mechanic pending browser test **[alpha]** **[L3]** `18oe_testing`
- [t] **Swift Metropolitan Line** — SR `choose` action (Phase 4+); claim_sml_train! assigns rusted 2+2 outside train limit (buyable=false, rusted=true); num_corp_trains + must_buy_train? exclude SML train; route restriction §11.3.8 free via base check_overlap **[alpha]** **[L2]** `18oe_testing`
- [t] **Brandt & Brandau** — `count_per_or: 2` + free tile wired; routing exclusion implemented (non-owning RRs blocked via `@bbe_hexes`); **still needed**: removal mechanic (pay terrain cost + tile point) **[alpha]** **[L2]** `18oe_testing`
- [t] **Barclay, Bevan, Barclay & Tritton** — option 3 (block DOWN): `bbbt_protect!` sets `@bbbt_protected_corp`; `sell_shares_and_change_price` override passes `movement: :none`; `finish_bbbt_sr!` clears + closes at SR end; options 1 (re-par) and 2 (reserve share) deferred to beta **[alpha]** **[L2]** `18oe_testing`
- [~] **Wien Südbahnhof** — `token` (price: 0, teleport_price: 0, extra_action: true) wired; **still needed**: cost-bypass in Token step (standard reachability still applies per §14.3) + sea-zone crossing costs still charged **[beta]** **[L2/L3]** `18oe_testing`
- [~] **Star Harbor** — `token` (extra_slot, special_only) wired; **still needed**: port routing, revenue exclusion, SR window **[beta]** **[L3]** `18oe_testing`
- [~] **White Cliffs Ferry** — `token` (hexes: ['N31']) wired; **still needed**: Phase 5 start event hook + ferry routing **[beta]** **[L3]** `18oe_testing`

## Nationals
- [>] Rusted train claim **[beta]** **[L2/L3]** `18oe_mergers`

## Minor Mergers
- [>] Minor SR merge action **[beta]** **[L2/L3]** `18oe_mergers`
- [>] Plumbing / can_merge **[beta]** **[L2/L3]** `18oe_mergers`
- [>] merge_minor! **[beta]** **[L2/L3]** `18oe_mergers`

---

## Active Workarounds

**WA-1** *(BETA SCOPE)* — `national_revenue` linked/unlinked split unverified. To remove: confirm `Graph.new(home_as_token: true, no_blocking: true)` correctly identifies linked nodes in a test game. Not relevant until nationalization is implemented.

**WA-5** *(PERMANENT)* — Silent `skip!` in `ConvertToNational` when queue empty. Correct behaviour — do not remove. See `MD/decisions.md` ADR-005.

---

## Branch Status *(updated 2026-05-19)*

| Branch | Base | Status | Contents |
|--------|------|--------|----------|
| `18oe_abilities` | upstream/master | deleted — merged into 18oe_testing | Minor C/D/J/L + private abilities wiring |
| `18oe_gamefixes` | upstream/master | closed (split) | superseded by PRs #47–51 |
| `18oe_mergers` | upstream/master | rebased ✓ | Minor SR merger · national formation · SR fixes |
| `18oe_testing` | upstream/master | rebased ✓ | Integration: gamefixes + abilities + mergers |
| `18oe_fix_par_prices` | upstream/master | deleted — merged ✓ tobymao#12601 | par price fix |
| `18oe_fix_share_price_movement` | upstream/master | deleted — merged ✓ tobymao#12602 | BUG-013/014 |
| `18oe_fix_president_overcap` | upstream/master | deleted — merged ✓ tobymao#12603 | BUG-021 |
| `18oe_fix_stock_terrain` | upstream/master | deleted — merged ✓ tobymao#12604 | BUG-008/009/010/015/022 |
| `18oe_fix_level8_gameend` | upstream/master | deleted — merged ✓ tobymao#12605 | BUG-018/024/025/027 |
