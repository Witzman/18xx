# Common Implementation Patterns

Short recipes for the most frequently needed game mechanics. Each pattern names the hook to override, shows a minimal implementation, and points to a production title that uses it.

---

## Revenue Patterns

### Hex revenue bonus

A route that visits a specific hex earns extra revenue.

```ruby
# In game.rb
BONUSES = { 'F8' => 20, 'D4' => 30 }.freeze

def revenue_for(route, stops)
  super + stops.sum { |s| BONUSES.fetch(s.hex.id, 0) }
end
```

Reference: `lib/engine/game/g_18co/game.rb`

---

### East-west route bonus

A corporation earns a bonus when its route set collectively spans east and west edges.

```ruby
EAST_HEXES = %w[A3 A5 A7].freeze
WEST_HEXES = %w[M3 M5 M7].freeze

def routes_revenue(routes)
  base = routes.sum(&:revenue)
  all_stops = routes.flat_map(&:stops).map { |s| s.hex.id }
  bonus = (all_stops & EAST_HEXES).any? && (all_stops & WEST_HEXES).any? ? 80 : 0
  base + bonus
end
```

Reference: `lib/engine/game/g_1830/game.rb`

---

### Revenue multiplier for a special train

Double the revenue of E-trains or other high-tier trains.

```ruby
def revenue_for(route, stops)
  base = super
  route.train.name == 'E' ? base * 2 : base
end
```

---

## Route Validation Patterns

### Mandatory home-city inclusion

Every route must pass through the corporation's home city.

```ruby
def check_other(route)
  home = route.corporation.coordinates
  return if route.stops.any? { |s| s.hex.id == home }
  raise GameError, "#{route.corporation.name} must include its home city"
end
```

Reference: `lib/engine/game/g_18chesapeake/game.rb`

---

### Route must reach an off-map hex

```ruby
REQUIRED_EXIT = %w[A1 A3].freeze   # at least one route must end here

def check_route_combination(routes)
  exits = routes.flat_map(&:stops).select { |s| s.hex.offboard? }.map { |s| s.hex.id }
  return if (exits & REQUIRED_EXIT).any?
  raise GameError, 'At least one route must reach an off-map space'
end
```

---

### Limit on routes sharing the same city

Standard 18xx rules prohibit two of the same corporation's routes from counting the same city twice.

```ruby
def check_route_combination(routes)
  # Base engine already checks path overlap; add city-level check:
  city_stops = routes.flat_map { |r| r.stops.select(&:city?) }
  dupes = city_stops.group_by(&:itself).select { |_, v| v.size > 1 }.keys
  raise GameError, "Route shares city #{dupes.first.hex.id}" if dupes.any?
end
```

---

## Dividend Patterns

### Half-pay dividend type

Add a "half" option alongside payout and withhold.

```ruby
# In step/dividend.rb (or a title-specific subclass)
DIVIDEND_TYPES = %i[payout half withhold].freeze

def dividend_types
  DIVIDEND_TYPES
end

def half(entity, revenue)
  per_share = (revenue / 2 / entity.total_shares).floor
  { corporation: revenue - (per_share * entity.total_shares), per_share: per_share }
end
```

Then register your step in `operating_round`:

```ruby
require_relative 'step/dividend'

def operating_round(round_num)
  Round::Operating.new(self, [
    # ... other steps ...
    G8888::Step::Dividend,
    # ...
  ], round_num: round_num)
end
```

Reference: `lib/engine/game/g_1822/step/dividend.rb`

---

### Stock price holds on half-pay

```ruby
# In the custom Dividend step
def share_price_change(entity, revenue)
  case @dividends_paid
  when :payout  then { share_direction: :right, share_times: 1 }
  when :half    then {}   # no movement
  when :withhold then { share_direction: :left, share_times: 1 }
  end
end
```

---

## Tile Lay Patterns

### Extra free tile lay via company ability

Give a private company the ability to lay one free tile on a specific hex. No custom Step needed — the `tile_lay` ability and `Step::SpecialTrack` handle it automatically.

```ruby
# In entities.rb COMPANIES
{
  name:    'Bavarian Central Railway',
  sym:     'BCR',
  value:   80,
  revenue: 15,
  abilities: [
    { type: 'blocks_hexes', owner_type: 'player', hexes: ['D8'] },
    {
      type:       'tile_lay',
      owner_type: 'corporation',
      hexes:      ['D8'],
      tiles:      %w[3 4 58],
      when:       'owning_corp_or_turn',
      count:      1,
    },
  ],
  color: nil,
}
```

The owning corporation gets one free tile lay on D8 per OR. `Step::SpecialTrack` must be in your `operating_round` step list (it is in the default list).

---

### `tile_lays` slot mechanics

`tile_lays(entity)` returns an **ordered array of lay-slot hashes**. Each slot is one available lay action, consumed in sequence as `@round.num_laid_track` is incremented.

```ruby
# Slot hash keys:
{ lay: true,                    # true / false / :not_if_upgraded
  upgrade: true,                # true / false / :not_if_upgraded
  cost: 0,                      # extra cost for yellow lays
  upgrade_cost: 0,              # extra cost for upgrades (defaults to :cost)
  cannot_reuse_same_hex: false  # prevents laying on same hex twice
}
```

`ability.use!` on a `tile_lay` ability routes through `lay_tile_action` when `consume_tile_lay: true` (consumes a slot) or through `lay_tile` directly when omitted (extra on top of the normal budget).

---

### Corporation gets two tile lays per OR

```ruby
# In game.rb
TILE_LAYS = [
  { lay: true, upgrade: true },
  { lay: :not_if_upgraded, upgrade: false, cost: 20 },
].freeze
```

The second element is the second lay: `lay: :not_if_upgraded` means the second action may only lay a new tile (not upgrade an existing one). `cost: 20` charges $20 for the second lay.

Reference: `lib/engine/game/g_1849/game.rb`

---

## Token Patterns

### Free token placement via teleport ability

A private company grants the owning corporation a free token placement anywhere on the board, bypassing connectivity.

```ruby
# In entities.rb COMPANIES
{
  name: 'Steamboat Company',
  sym:  'SBC',
  value: 30,
  revenue: 5,
  abilities: [
    {
      type:       'teleport',
      owner_type: 'corporation',
      tiles:      %w[57 14 15],
      hexes:      [],          # empty = any hex
    },
  ],
  color: nil,
}
```

`Step::SpecialToken` must be in your `operating_round` step list.

---

### Corporation starts with two home tokens

```ruby
# In entities.rb CORPORATIONS
{
  sym:         'PRR',
  coordinates: 'H12',
  second_city: 'F14',   # second home token placed here at game start
  # ...
}
```

---

## Phase & Event Patterns

### Custom event method

When a train fires an event, the engine calls `game.send("event_#{type}!")`. Define the method in `game.rb`:

```ruby
# Fired when the first 5-train is purchased
def event_close_companies!
  @log << '-- Event: Private companies close --'
  super
end
```

Call `super` to run the base class logic (closing companies, etc.) before or after your additions.

---

### Gating a train behind a purchase count (not just available_on)

`available_on:` makes a train visible in the depot after a named train tier is bought, but it does not enforce a purchase *count*. To require N copies of a prior train to be bought first, combine `available_on:` (for depot visibility) with a `buyable_trains` filter in a custom BuyTrain step:

```ruby
# In TRAINS (game.rb) — depot surfaces the 8+8 once 7+7 phase is active
{ name: '8+8', available_on: '7+7', ... }

# In step/buy_train.rb — additional count gate
def buyable_trains(entity)
  trains = super
  trains = trains.reject { |t| t.name == '8+8' } unless @game.level8_train_available?
  trains
end

# In game.rb
def level8_train_available?
  sold = depot.trains.count { |t| t.name == '7+7' } - depot.upcoming.count { |t| t.name == '7+7' }
  sold >= 4
end
```

Reference: `lib/engine/game/g_18_oe/game.rb`, `lib/engine/game/g_18_oe/step/buy_train.rb`

---

### Injecting remainder cash into the bank on a train event

Some physical games set aside extra notes at setup and inject them when a specific train is bought, to prevent the bank from breaking prematurely during the final OR set. Model this with a one-shot event method guarded by an instance variable:

```ruby
# In game.rb
REMAINDER_CASH = 100_000   # e.g. 20 × £5,000 notes (§13)

def event_remainder_cash!
  return if @remainder_cash_added
  @remainder_cash_added = true
  @bank.instance_variable_set(:@cash, @bank.cash + self.class::REMAINDER_CASH)
  @log << "-- Event: #{format_currency(self.class::REMAINDER_CASH)} remainder cash added to bank --"
end
```

Wire it via `events:` on the relevant train in `TRAINS`:

```ruby
{ name: '8+8', events: [{ 'type' => 'remainder_cash' }], ... }
```

The guard (`return if @remainder_cash_added`) ensures only the first purchase fires the injection even though the event fires for every 8+8 bought.

Reference: `lib/engine/game/g_18_oe/game.rb`

---

### Phase-gated action in a Step

Check the current phase status inside a Step's `actions` method to enable or disable options:

```ruby
def actions(entity)
  return [] unless @game.phase.status.include?('can_buy_companies')
  super
end
```

---

## Operating Order Patterns

### Custom operating order

Override `operating_order` in `game.rb`:

```ruby
# Corporations with destination tokens operate before others
def operating_order
  without_dest, with_dest = super.partition { |c| !destination_reached?(c) }
  without_dest + with_dest
end
```

Reference: `lib/engine/game/g_1889/game.rb`

---

### Minors operate before majors

The default `operating_order` already does this. To reverse it:

```ruby
def operating_order
  floated_majors = corporations.select { |c| c.type == :major && c.floated? }
  floated_minors = minors.select(&:floated?)
  (floated_majors + floated_minors).sort_by { |c| [c.share_price.price, c.share_price.corporations.index(c)] }.reverse
end
```

---

## Finding More Examples

The fastest way to find a production example of any pattern:

```bash
# Find titles that override revenue_for:
grep -rl "def revenue_for" lib/engine/game/

# Find titles that define a half-pay step:
grep -rl "half" lib/engine/game/*/step/

# Find all titles that use a specific ability type:
grep -rl "type: 'teleport'" lib/engine/game/
```

---

## What's Next

- Revenue hook reference: [Revenue & Routing](revenue-routing.html)
- Ability field reference: [Abilities](abilities.html)
- Writing a custom Step from scratch: [Rounds & Steps](round-step-system.html)
- Verifying patterns with fixtures: [Testing Your Game](testing.html)

---
*Version: 2026-05-08 — derived from production game titles in `lib/engine/game/`, `lib/engine/step/`, `lib/engine/game/base.rb`.*
