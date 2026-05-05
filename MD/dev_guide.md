# 18xx Engine Developer Cheat Sheet

Quick reference for the four-class API of the `18xx` engine: `Game::Base`,
`Round::Base`, `Step::*`, `Action::*`. For the deep reference (full layer taxonomy,
event dispatch, OR step sequence, edge cases, invariants), see `MD/ENGINE_MECHANICS.md`.

**Scope of this file.** Code patterns you'll reach for in a typical implementation
session: which method to override, which extension hook to use, which test pattern
to copy. **Not in scope:** the Layer 1–4 taxonomy, ability semantics, the FE.

> If a section here disagrees with `ENGINE_MECHANICS.md`, the latter wins.

---

## 1. Core Architecture (one paragraph)

The engine is split into four classes. `Game::Base` holds shared rules and is
sub-classed per title (`G18OE`). `Round::Base` runs the steps for a phase
(stock, operating). `Step::*` are atomic phases (lay track, buy train, place
token). `Action::*` are the units the FE submits — they flow through the round
and dispatch to the active step. Almost every 18xx variant is implemented by:

1. New `CONSTANTS` (Layer 1).
2. A handful of named method overrides on `Game::Base` (Layer 2).
3. New `Step` or `Round` classes for novel mechanics (Layer 3).

---

## 2. Game::Base

| Method | Role |
|---|---|
| `setup` | Initialise bank, players, corporations, custom hashes |
| `operating_round(num)` | Start an OR set |
| `stock_round` | Start a SR |
| `route_trains(entity)` | Resolve train runs and revenue |
| `buy_train(entity, train, price)` | Apply a train purchase |
| `merge(entities)` | Corporation merge — usually overridden by titles |

**Usage:**

```ruby
game = Engine::Game::G18OE.new(players)
round = game.operating_round(1)
action = Engine::Action::BuyTrain.new(entity, train, price: 300)
round.process_action(action)
```

---

## 3. Round::Base

Rounds collect available actions per entity and dispatch incoming actions to the
active step.

```ruby
steps.each(&:actions)        # collect allowed actions per entity
round.process_action(action) # delegates to the active Step
```

---

## 4. Step::*

Atomic phases of gameplay. Examples used in 18OE:

- `Step::HomeToken`
- `Step::Track`
- `Step::Token`
- `Step::Dividend`
- `Step::BuyTrain`
- `Step::BuySellParShares`
- `Step::WaterfallAuction` (custom)
- `Step::Consolidate` (custom, partial)
- `Step::ConvertToNational` (custom)

Common API every step implements:

```ruby
actions(entity)             # returns allowed actions for the entity
process_buy_train(action)   # executes a specific action type
process_merge(action)       # ditto
```

---

## 5. Action::*

Player actions, serialisable to/from a hash:

```ruby
Engine::Action::BuyTrain.new(entity, train, price)
Engine::Action::SellShares.new(entity, shares)

action.to_h          # serialise
Action.from_h(h)     # deserialise
```

---

## 6. Call Sequence

```text
Game.new(players)
  → setup()
  → stock_round()
  → operating_round()
       → each step:
           actions(entity)
           process_action(action)
```

---

## 7. Patterns to Copy from Other Titles

When implementing a 18OE mechanic, the fastest way is usually to find a similar
mechanic elsewhere and adapt. Top picks:

| You need… | Look at | Why |
|---|---|---|
| National companies (state-owned mid-game systems) | `g_1844`, `g_1854` | Same merge-into-national pattern; trigger via `Step::Merge` + extended `Game#merge` |
| Mergers with stock conversion | `g_1828`, `g_1841` | Closest to 18OE minor→major and consolidation merge logic |
| Combining trains (level ≤4) | `g_1862` | The combined-distance pattern 18OE needs for OE runs |
| Ferries / ports | `g_18_mex`, `g_18_scan` | `Step::Assign`, `hex.assignments` for ferry tokens and port bonuses |
| Sea zones / province crossing | `g_18_c2c`, `g_18_oe` (this game) | Track + route validators check `hex.province` / `hex.sea_zone` |
| Waterfall auction | `g_1817` family, `g_18_oe` | 18OE's `step/waterfall_auction.rb` is a stable reference |

---

## 8. Test Patterns

Specs live in `18xx/spec/`. The most-copied patterns:

```ruby
expect(game.round.active_step.actions(entity))

round = game.operating_round(1)
buy_action = Engine::Action::BuyTrain.new(corp, train, price: 200)
round.process_action(buy_action)

merge_action = Engine::Action::Merge.new(corp_a, corp_b)
round.process_action(merge_action)
```

For a smoke spec you can drop in immediately, see `MD/commands.md`.

---

## 9. Extension Hooks (when adding a new mechanic)

- Add a new `Step` if the mechanic is a discrete player action with its own
  `actions(entity)` set.
- Add or extend a `Round` if the mechanic introduces a new round type
  (Concession, Consolidation).
- Override `Game::merge` / `Game::route_trains` / `Game::operating_order` /
  `Game::next_round!` for behaviour that's title-specific but doesn't need its
  own step.
- Wire the new action(s) into `actions(entity)` in the relevant step.

When in doubt, use the layer taxonomy in `ENGINE_MECHANICS.md` to decide between
"override an existing method" (Layer 2) and "write a new step or round" (Layer 3).
18OE has no Layer 4 mechanics — if you find yourself wanting to subclass
`Game::Base` itself or fork the round dispatcher, you're going in the wrong
direction.
