# 18OE — Bug Log

Curated list of known defects and their fixes. Entries are immutable IDs (`BUG-NNN`);
status changes over time but the ID and original description do not.

**Status values:** `OPEN` (unfixed), `FIXED` (with commit hash + date), `WONTFIX`
(with reason), `INVESTIGATING` (under triage).

**Severity:** HIGH (blocks correct gameplay), MEDIUM (rule violation in edge case or
narrow window), LOW (cosmetic or low-impact).

When you fix a bug, change `Status:` to `FIXED <date> <commit>` and move the entry
to the **Resolved** section. Do not delete entries — the history is the value.

---

## Open

### BUG-001 — `can_buy?` blocks non-presidents from secondary shares in Major Phase

- **Status:** OPEN
- **Severity:** HIGH
- **File:** `lib/engine/game/g_18_oe/step/buy_sell_par_shares.rb:60–72`
- **Rule:** §8.3 — *"Secondary shares of regionals are available [in the Major RR Phase]."* No president-only restriction.

**Symptom.** When `@converting` is `nil` (i.e. no conversion in progress, normal Major Phase) and a non-president player tries to buy a secondary share of a regional from its IPO, `can_buy?` returns `false`. Only the president can buy, contradicting §8.3.

**Root cause.** The guard intended to enforce §9.3 step 1 (only the president may buy one share before converting) is too broad. `!@converted` matches both the `@converting` state *and* normal Major Phase.

```ruby
# current — wrong
if !@converted && bundle.corporation.type == :regional &&
   bundle.corporation.ipoed && bundle.owner == bundle.corporation
  return false unless bundle.corporation.president?(entity)   # too broad
  return false if @bought == bundle.corporation               # see BUG-002
end
```

**Fix.** Scope the restriction to the pre-conversion state only:

```ruby
# proposed
if @converting == bundle.corporation
  return false unless bundle.corporation.president?(entity)
  return false if bought_corporation == bundle.corporation
end
```

---

### BUG-002 — `@bought` ivar removed but still referenced; double-buy not blocked

- **Status:** OPEN
- **Severity:** HIGH
- **File:** `lib/engine/game/g_18_oe/step/buy_sell_par_shares.rb:68`
- **Rule:** §9.3 step 1 — *"the player may purchase ONE share prior to step 2."*

**Symptom.** During pre-conversion in the Major Phase, a president can buy multiple treasury shares before triggering the conversion, violating the one-share rule.

**Root cause.** `@bought` was removed in the `bought_corporation` refactor; the line `return false if @bought == bundle.corporation` always evaluates `nil == corp` → `false`, so the guard never fires.

**Fix.** Replace `@bought` with the helper:

```ruby
return false if bought_corporation == bundle.corporation
```

(Same change is implicit in the BUG-001 fix above; if both fixes ship together the line lives only in the `@converting` branch.)

---

### BUG-003 — Post-conversion sell window skipped when player is already president

- **Status:** OPEN
- **Severity:** MEDIUM
- **File:** `lib/engine/game/g_18_oe/step/buy_sell_par_shares.rb:267–273`
- **Rule:** §9.3 — *"Optional — the active player may sell any number of shares of any RR they already own (not the newly floated major)."*

**Symptom.** When the converting player is already the regional's president, the conversion completes and the turn ends in the same `pass!` call. The optional sell window (and the optional post-conversion share purchase, step 5) is never offered.

**Root cause.** `pass!` calls `complete_conversion` then falls straight through to `super`:

```ruby
# current
def pass!
  complete_conversion if @converting   # sets @converted
  raise GameError, "..." if @converted && !@converted.president?
  super   # always ends the turn if no error raised
end
```

**Fix.** After `complete_conversion`, return early. A second `pass!` call (with `@converting` cleared and `@converted` set) ends the turn:

```ruby
def pass!
  if @converting
    complete_conversion
    raise GameError, "..." unless @converted.president?
    return  # offer sell + buy window
  end
  super
end
```

---

### BUG-004 — `can_sell?` blocks all regional share selling, including in Major Phase

- **Status:** OPEN — needs rule verification
- **Severity:** MEDIUM
- **File:** `lib/engine/game/g_18_oe/step/buy_sell_par_shares.rb` (`can_sell?`)
- **Rule:** §10 (selling rules) — needs confirmation that secondary regional shares are sellable in Major Phase.

**Symptom.** `can_sell?` contains `return false if bundle.corporation.type == :regional`, which blocks all sale of regional shares regardless of phase. In Major Phase, secondary regional shares should be both buyable (§8.3) and sellable. This also means the §9.3 post-conversion sell window can never include other regionals' secondary shares.

**Hypothesis.** The block was intended to prevent president-share dumps but is too broad.

**Required before fix.** Confirm against §10 that selling secondary regional shares in Major Phase is permitted. Then narrow the guard to "president certificate" or "the regional whose conversion this turn is in progress".

---

### BUG-005 — RCP cannot lay track

- **Status:** INVESTIGATING
- **Severity:** Unknown (likely HIGH if reproducible)
- **Source:** Original short note in `bugs.md` ("rcp cant lay track").

**Symptom (reported).** When operating, RCP (a Spanish regional) cannot lay any track tile.

**Diagnosis steps.**

1. Confirm the failure mode: is the `lay_tile` action absent from `actions(entity)`, is it raising a GameError, or is the tile-budget exhausted?
2. Check `Step::Track#available_hex` — likely the zone restriction (`hex_within_national_region?`) is over-rejecting because RCP's home zone is `SP` and the connection candidates may be filtered out.
3. Reproduce in a 4-player test game where RCP is floated and operates in Phase 2.
4. Compare with another SP-zone regional (MZA) — if MZA can lay and RCP cannot, the bug is RCP-specific (entity definition); if both fail, it is zone-system wide.

**Owner:** TBD.

---

### BUG-006 — Minors always pay half dividend (no choice offered)

- **Status:** INVESTIGATING
- **Severity:** Unknown (likely MEDIUM)
- **Source:** Original short note in `bugs.md` ("minors always pay half").

**Symptom (reported).** Minor corporations always perform a half-pay dividend, regardless of whether the operating player attempted to choose another option.

**Expected.** Per §6d, minors are restricted to half-pay only — so "always half-pay" is technically correct. The bug may instead be that the **UI offers no choice to acknowledge** the dividend, or that `withhold` produces a misleading error, or that the half-pay rounding is incorrect.

**Diagnosis steps.**

1. Read `Step::Dividend#dividend_options` for `:minor` corporations — confirm only `:half` is returned.
2. Check whether the UI shows "Pay Half" as the only button. If yes, behaviour is rule-correct; close as `WONTFIX (rule)`.
3. If the original report was about the half-pay arithmetic, run a test: minor with £30 revenue and 1 share — expected payout per share is £15; treasury keeps £15. Confirm.

**Owner:** TBD.

---

## Resolved

*(No resolved bugs yet. When a bug above is fixed, move it here with status updated to `FIXED <YYYY-MM-DD> <commit-hash>` and a short note about the actual fix landed.)*

---

## Conventions

- **One ID per defect, ever.** If a bug recurs after being fixed, open a new entry that links back: `Status: REOPENED — superseded by BUG-NNN`.
- **Rule citations are mandatory** for HIGH/MEDIUM bugs. If a bug is "wrong but rules are silent," that's a `decisions.md` ADR, not a bug.
- **Fix sections must include the diff direction**, not just the new code, so that future readers can see what the change does.
