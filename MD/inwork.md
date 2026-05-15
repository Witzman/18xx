# 18OE — In Work

Items currently in flight: `[~]` in development · `[t]` implemented, testing in progress · `[>]` all tests passed, needs PR.

Move items here from `MD/todo.md` at session start. Move to `MD/done.md` when complete + PR merged.

Layers: L1 constants · L2 Game::Base override · L3 new Step/Round file
Branch tag: backtick-wrapped branch name at end of each item line; `?` = branch not yet recorded

Items without a milestone tag = **alpha**. `[BETA]` = deferred to beta milestone.

---

## Track Rights
- [>] 20% terrain discount zones **[alpha]** **[L2]** `18oe_fix_stock_terrain` tobymao#12604

## Stock Market Grid
- [>] LEFT (zero dividend) **[alpha]** **[L2]** `18oe_fix_share_price_movement` tobymao#12602
- [>] No movement (below par) **[alpha]** **[L2]** `18oe_fix_share_price_movement` tobymao#12602
- [>] RIGHT (at/above par) **[alpha]** **[L2]** `18oe_fix_share_price_movement` tobymao#12602
- [>] Sold-out order (hi→lo price) **[alpha]** **[L2]** `18oe_fix_stock_terrain` tobymao#12604
- [>] >60% president pool buy at 2× **[alpha]** **[L2]** `18oe_fix_president_overcap` tobymao#12603
- [>] §11.7 issuance DOWN movement **[alpha]** **[L2]** `18oe_fix_stock_terrain` tobymao#12604

## Train Data & Phases
- [>] L8 unlock after 4th L7 **[alpha]** **[L2]** `18oe_fix_level8_gameend` tobymao#12605

## End Game
- [>] Bank break pre-L8 timing **[alpha]** **[L2]** `18oe_fix_level8_gameend` tobymao#12605
- [>] L8 purchase end trigger **[alpha]** **[L2]** `18oe_fix_level8_gameend` tobymao#12605
- [>] Remainder cash injection **[alpha]** **[L2]** `18oe_fix_level8_gameend` tobymao#12605
- [>] Bankrupt trigger removed **[alpha]** **[L2]** `18oe_fix_level8_gameend` tobymao#12605

## Minor Abilities
- [>] J – Grey Locomotive **[alpha]** **[L1]** `18oe_abilities`
- [t] **C** (Golden Bell) — pre-OR blocking choice step (GoldenBellChoice); `first`/`last`/`normal`; entity order rebuilt from `operating_order` after choice **[alpha]** **[L3]** `18oe_abilities`
- [t] **D** (Green Junction) — DTokenPlacement step; assign action during track window; any non-metro non-offboard city; Phase 5 transition already wired **[alpha]** **[L3]** `18oe_abilities`
- [t] **L** (Krasnaya Strela) — KrasnayaStrelaAssign step wired; train-choice before Route step; D-train doubling exception deferred (see BUG-031) **[alpha]** **[L3]** `18oe_abilities`

## Private Abilities
- [t] **Central Circle** — hex_bonus approximation (£10/£20/£40/£60 by phase via after_phase_change); SR window via extra_action:true already wired; city-as-town routing deferred (see BUG-032) **[alpha]** **[L2]** `18oe_abilities`
- [t] **Hochberg Mining** — HochbergPlacement step (rough terrain ≥ £45); routing exclusion via check_route_token override; removal mechanic pending browser test **[alpha]** **[L3]** `18oe_abilities`
- [t] **Brandt & Brandau** — `count_per_or: 2` added; engine enforces cap automatically **[alpha]** **[L1]** `18oe_abilities`
- [~] **Wien Südbahnhof** — `token` (price: 0, teleport_price: 0, extra_action: true) wired; **still needed**: Token step zone-bypass + sea-zone crossing costs **[beta]** **[L2/L3]** `18oe_abilities`
- [~] **Star Harbor** — `token` (extra_slot, special_only) wired; **still needed**: port routing, revenue exclusion, SR window **[beta]** **[L3]** `18oe_abilities`
- [~] **White Cliffs Ferry** — `token` (hexes: ['N31']) wired; **still needed**: Phase 5 start event hook + ferry routing **[beta]** **[L3]** `18oe_abilities`

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

## Branch Status *(updated 2026-05-14)*

| Branch | Base | Status | Contents |
|--------|------|--------|----------|
| `18oe_abilities` | upstream/master | rebased ✓ | Minor C/D/J/L + private abilities wiring |
| `18oe_gamefixes` | upstream/master | closed (split) | superseded by PRs #47–51 |
| `18oe_mergers` | upstream/master | rebased ✓ | Minor SR merger · national formation · SR fixes |
| `18oe_testing` | upstream/master | rebased ✓ | Integration: gamefixes + abilities + mergers |
| `18oe_fix_par_prices` | upstream/master | fork #52 / upstream #12601 open | par price fix |
| `18oe_fix_share_price_movement` | upstream/master | fork #53 / upstream #12602 open | BUG-013/014 |
| `18oe_fix_president_overcap` | upstream/master | fork #54 / upstream #12603 open | BUG-021 |
| `18oe_fix_stock_terrain` | upstream/master | fork #55 / upstream #12604 open | BUG-008/009/010/015/022 |
| `18oe_fix_level8_gameend` | upstream/master | fork #56 / upstream #12605 open | BUG-018/024/025/027 |
