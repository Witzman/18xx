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
- [>] National name on conversion — `NATIONAL_NAMES` constant; `convert_to_national` sets `corporation.full_name`; §1.3.1 **[alpha]** **[L1+L2]** `18oe_testing`
- [>] BBE markers cleared on conversion — `@bbe_hexes.delete_if` in `convert_to_national`; §9.4/§1.3d **[alpha]** **[L2]** `18oe_testing`
- [>] `eligible_majors_for(player)` extracted to `game.rb`; `ConvertToNational` + `trigger_nationals_formation!` updated **[alpha]** **[L2]** `18oe_testing`

## Minor Mergers
- [>] Minor SR merge action **[beta]** **[L2/L3]** `18oe_mergers`
- [>] Plumbing / can_merge **[beta]** **[L2/L3]** `18oe_mergers`
- [>] merge_minor! **[beta]** **[L2/L3]** `18oe_mergers`

## Consolidation Phase
- [>] Merge action in Consolidate step — `process_merge` without auto-pass; multi-merge per turn; §10.5/§10.6 **[alpha]** **[L3]** `18oe_testing`
- [>] Abandon action + `abandon_minor!` — `choose` dropdown for stranded minors; trains → depot discarded; §9.5 **[alpha]** **[L2/L3]** `18oe_testing`
- [>] Force-abandon surviving minors at Consolidation round end — `force_abandon_surviving_minors!` called from `next_round!`; §10.6 **[alpha]** **[L2]** `18oe_testing`
- [>] Block abandon when convertible regional present — `abandonable_minors` guard; §10.6/§3126 **[alpha]** **[L2]** `18oe_testing`

---

## Active Workarounds

**WA-1** *(BETA SCOPE)* — `national_revenue` linked/unlinked split unverified. To remove: confirm `Graph.new(home_as_token: true, no_blocking: true)` correctly identifies linked nodes in a test game. Not relevant until nationalization is implemented.

**WA-5** *(PERMANENT)* — Silent `skip!` in `ConvertToNational` when queue empty. Correct behaviour — do not remove. See `MD/decisions.md` ADR-005.

---

## Upstream PR Todo

| Bug / Feature | Fix commit | Branch | Notes |
|---------------|-----------|--------|-------|
| BUG-044 majors unrestricted track/token | `fb2a420d3` (18oe_testing) | needs new branch off upstream/master | 2-line change, 18OE-specific |
| Double-town tiles OE9–OE22 + DoubleTownPart routing | `77e1a2a9a`–`9ce4cbc62` (18oe_tiles) | **PR #12667 open — reworked** | Replaced size:2+game-override with `Part::DoubleTown < Town`; walk marks both sub-stops; `base.rb#visited_stops` expands via `sub_stops`; G18OE overrides deleted; OE10=£20 IRB verified; tile gallery rendering confirmed; awaiting crericha re-review |
| OE10/OE20 exit fix + full upgrade chain browser test | `1d70e5f2c` + `404232f4d` (18oe_tiles, merged 18oe_testing) | **TODO: browser test only** | exits fixed; IRB confirmed OE10→OE20 ✓ OE9→OE20 ✗; need browser: upgrade preprinted double-town (e.g. J29) yellow→green (OE9/10/11)→brown (OE20/21/22) |

---

## Branch Status *(updated 2026-06-04)*

| Branch | Base | Status | Contents |
|--------|------|--------|----------|
| `18oe_guidelines` | upstream/master | PR open tobymao#12647 | Coding guidelines + bug fixes (upstream-safe): BUG-039/040/041 + 5 cleanups |
| `18oe_abilities` | upstream/master | deleted — merged into 18oe_testing | Minor C/D/J/L + private abilities wiring |
| `18oe_gamefixes` | upstream/master | closed (split) | superseded by PRs #47–51 |
| `18oe_mergers` | upstream/master | rebased ✓ | Minor SR merger · national formation · SR fixes |
| `18oe_testing` | upstream/master | active ✓ | Integration: gamefixes + abilities + mergers + nationals + consolidation |
| `18oe_tiles` | upstream/master | PR #12667 open — reworked 2026-06-04 | `Part::DoubleTown` replaces size:2+game-override; 14 IRB tests pass; tile gallery ✓; £20 revenue IRB ✓; awaiting crericha re-review |
| `18oe_fix_par_prices` | upstream/master | deleted — merged ✓ tobymao#12601 | par price fix |
| `18oe_fix_share_price_movement` | upstream/master | deleted — merged ✓ tobymao#12602 | BUG-013/014 |
| `18oe_fix_president_overcap` | upstream/master | deleted — merged ✓ tobymao#12603 | BUG-021 |
| `18oe_fix_stock_terrain` | upstream/master | deleted — merged ✓ tobymao#12604 | BUG-008/009/010/015/022 |
| `18oe_fix_level8_gameend` | upstream/master | deleted — merged ✓ tobymao#12605 | BUG-018/024/025/027 |
