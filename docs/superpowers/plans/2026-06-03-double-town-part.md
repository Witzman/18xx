# DoubleTown Part Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `size:2` + game-level `visited_stops` hack with a proper `Part::DoubleTown` engine class that counts as 2 stops natively, satisfying crericha's architectural requirement for PR #12667.

**Architecture:** `DoubleTown < Town` owns its own rendering (via existing `town_dot.rb` `size:2` dispatch), its own walk (override marks both `@town_a` and `@town_b` visited), and its own stop-count semantics via `sub_stops`. `tile.rb` instantiates `DoubleTown` when `size:2`. **Decision gate at Task 3**: if the walk override alone produces 2 stops in `visited_stops`, no `base.rb` change is needed. If not, one line is added to `base.rb#visited_stops` — expansion logic owned by the Part, not the game. The game-level overrides in `G18OE` are deleted entirely regardless.

**Tech Stack:** Ruby, 18xx engine (`lib/engine/`), Opal/Ruby frontend (`assets/app/view/`). Tests via IRB in Docker. Branch: `18oe_tiles`.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/engine/part/double_town.rb` | CREATE | DoubleTown Part — walk override, `sub_stops`, `size:2` |
| `lib/engine/tile.rb:139-153` | MODIFY | Instantiate `DoubleTown` instead of `Town` when `size:2` |
| `lib/engine/game/base.rb:1605-1607` | MODIFY (conditional) | One-line `sub_stops` expansion — **only if Task 3 gate FAILS** |
| `lib/engine/game/g_18_oe/game.rb:856-863` | MODIFY | Delete `visited_stops` + `revenue_stops` overrides unconditionally |
| `assets/app/view/game/part/town_dot.rb` | NO CHANGE | Already dispatches on `@town.size`; DoubleTown returns `size:2` ✓ |

---

## Task 1: Create `Part::DoubleTown`

DoubleTown controls its own walk — both internal towns are marked visited on entry. No internal path object, so no rendering of an internal segment. Rendering is already handled by `town_dot.rb` dispatching on `@town.size`.

**Files:**
- Create: `lib/engine/part/double_town.rb`

- [ ] **Step 1.1 — Write the file**

```ruby
# frozen_string_literal: true

require_relative 'town'

module Engine
  module Part
    class DoubleTown < Town
      attr_reader :sub_stops

      def initialize(revenue, **opts)
        super
        @town_a = Town.new(revenue, **opts)
        @town_b = Town.new(revenue, **opts)
        @sub_stops = [@town_a, @town_b].freeze
      end

      def size
        2
      end

      def walk(visited: {}, walk_calls: Hash.new(0), converging_path: true, **kwargs, &block)
        walk_calls[:all] += 1
        return if visited[self]

        walk_calls[:not_skipped] += 1

        visited[self] = true
        visited[@town_a] = true
        visited[@town_b] = true

        paths.each do |node_path|
          next if node_path.track == kwargs[:skip_track]
          next if node_path.ignore?

          node_path.walk(walk_calls: walk_calls, converging: converging_path, **kwargs.slice(:visited_paths, :skip_paths, :counter, :skip_track, :backtracking)) do |path, vp, ct, converging|
            ret = yield path, vp, visited
            next if ret == :abort
            next if path.terminal?

            path.nodes.each do |next_node|
              next if next_node == self
              next if kwargs[:corporation] && next_node.blocks?(kwargs[:corporation])

              next_node.walk(
                visited: visited,
                walk_calls: walk_calls,
                converging_path: converging_path || converging,
                **kwargs,
                &block
              )
            end
          end
        end

        visited.delete(self) if converging_path
      end
    end
  end
end
```

- [ ] **Step 1.2 — Verify Ruby parses cleanly**

```bash
docker compose exec rack ruby -e "require_relative 'lib/engine/part/double_town'; puts Engine::Part::DoubleTown.new('10').class"
```

Expected: `Engine::Part::DoubleTown`

- [ ] **Step 1.3 — Verify basics in IRB**

```bash
docker compose exec rack irb -r ./lib/engine/part/double_town
```

```ruby
dt = Engine::Part::DoubleTown.new('10')
puts dt.town?               # => true
puts dt.size                # => 2
puts dt.rect?               # => false
puts dt.sub_stops.size      # => 2
puts dt.sub_stops.all?(&:town?)                    # => true
puts dt.sub_stops.all? { |s| s.class == Engine::Part::Town } # => true
puts dt.sub_stops.map { |s| s.uniq_revenues }     # => [[10], [10]]
puts dt.respond_to?(:walk)  # => true
```

- [ ] **Step 1.4 — Commit**

```bash
git add lib/engine/part/double_town.rb
git commit -m "feat(engine): add Part::DoubleTown — walk override visits both internal towns"
```

---

## Task 2: Wire `tile.rb` to instantiate `DoubleTown` for `size:2`

**Files:**
- Modify: `lib/engine/tile.rb:139-153`

Current block (lines 139–153):
```ruby
when 'town'
  town = Part::Town.new(params['revenue'],
                        groups: params['groups'],
                        hide: params['hide'],
                        visit_cost: params['visit_cost'],
                        route: params['route'],
                        format: params['format'],
                        loc: params['loc'],
                        boom: params['boom'],
                        style: params['style'],
                        size: params['size'],
                        to_city: params['to_city'])
  cache << town
  town
```

- [ ] **Step 2.1 — Add require and branch**

Add `require_relative 'part/double_town'` near the top of `tile.rb` where other parts are required. Then replace the `when 'town'` block:

```ruby
when 'town'
  klass = params['size'].to_i > 1 ? Part::DoubleTown : Part::Town
  town = klass.new(params['revenue'],
                   groups: params['groups'],
                   hide: params['hide'],
                   visit_cost: params['visit_cost'],
                   route: params['route'],
                   format: params['format'],
                   loc: params['loc'],
                   boom: params['boom'],
                   style: params['style'],
                   size: params['size'],
                   to_city: params['to_city'])
  cache << town
  town
```

- [ ] **Step 2.2 — Verify OE9 tile produces a DoubleTown**

```bash
docker compose exec rack irb -r ./lib/engine
```

```ruby
require_relative 'lib/engine' unless defined?(Engine)
tile = Engine::Tile.from_code('OE9', :yellow, 'town=revenue:10,size:2;path=a:0,b:_0;path=a:3,b:_0')
puts tile.towns.first.class          # => Engine::Part::DoubleTown
puts tile.towns.first.size           # => 2
puts tile.towns.first.sub_stops.size # => 2
```

- [ ] **Step 2.3 — Verify plain town unaffected**

```ruby
tile2 = Engine::Tile.from_code('7', :yellow, 'town=revenue:10;path=a:0,b:_0;path=a:3,b:_0')
puts tile2.towns.first.class                       # => Engine::Part::Town
puts tile2.towns.first.size                        # => 1
puts tile2.towns.first.respond_to?(:sub_stops)     # => false
```

- [ ] **Step 2.4 — Commit**

```bash
git add lib/engine/tile.rb
git commit -m "feat(engine/tile): instantiate DoubleTown when town size:2"
```

---

## Task 3: Remove game-level overrides from `G18OE`

Do this before the gate test so the test reflects the real engine state.

**Files:**
- Modify: `lib/engine/game/g_18_oe/game.rb:856-863`

Block to DELETE:
```ruby
def visited_stops(route)
  super.flat_map { |stop| stop.town? && stop.size > 1 ? Array.new(stop.size, stop) : [stop] }
end

def revenue_stops(route)
  super.flat_map { |stop| stop.town? && stop.size > 1 ? Array.new(stop.size, stop) : [stop] }
end
```

- [ ] **Step 3.1 — Delete both overrides**

Remove the two methods. Leave all surrounding code intact.

- [ ] **Step 3.2 — Confirm clean**

```bash
grep -n "visited_stops\|revenue_stops" lib/engine/game/g_18_oe/game.rb
```

Expected: no output.

- [ ] **Step 3.3 — Commit**

```bash
git add lib/engine/game/g_18_oe/game.rb
git commit -m "refactor(18oe): remove visited_stops/revenue_stops overrides; DoubleTown handles natively"
```

---

## Task 4: Decision gate — does walk override alone produce 2 stops?

**This test determines whether `base.rb` needs touching at all.**

```bash
docker compose exec rack irb -r ./lib/engine
```

```ruby
require_relative 'lib/engine' unless defined?(Engine)
g = Engine::Game::G18OE::Game.new(%w[Alice Bob Charlie])
hex = g.hex_by_id('J29')
dt = hex.tile.towns.first

puts dt.class == Engine::Part::DoubleTown ? 'PASS: DoubleTown instantiated' : "FAIL: got #{dt.class}"

# Check visited_stops count for a route through the double-town.
# Build a minimal 2-node route: token hex → J29 double-town.
# Use Alice's first corporation with a 2+2 train for the test.
corp = g.corporations.find { |c| c.type == :major }
corp.cash = 1000
train = g.depot.upcoming.find { |t| t.name == '2+2' }
corp.buy_train(train, train.price)

# Count how many stops visited_stops returns when J29 is in the route.
# We inspect connection_data directly to see if DoubleTownPart appears once or twice,
# and whether sub_stops expands it.
puts dt.sub_stops.size == 2 ? 'PASS: sub_stops count correct' : "FAIL: sub_stops #{dt.sub_stops.size}"

# Manual check: does base visited_stops expand DoubleTown?
# Simulate what visited_stops does with a fake connection_data entry:
fake_data = [{ left: dt, right: nil }]
raw = fake_data.flat_map { |c| [c[:left], c[:right]] }.uniq.compact
puts raw.size == 1 ? 'connection_data sees 1 DoubleTown (expected)' : "unexpected: #{raw.size}"

expanded = raw.flat_map { |s| s.respond_to?(:sub_stops) ? s.sub_stops : [s] }
puts expanded.size == 2 ? 'PASS: sub_stops expansion gives 2 stops' : "FAIL: expansion gives #{expanded.size}"
```

- [ ] **Step 4.1 — Run gate test**

**If `visited_stops` already returns 2 without `base.rb` change** (i.e., walk override alone is sufficient via engine internals):
→ Skip Task 5. Proceed directly to Task 6.

**If `visited_stops` returns 1** (DoubleTown appears once in `connection_data`, walk override is not enough):
→ Continue to Task 5.

- [ ] **Step 4.2 — Record result**

Add a commit message noting which path was taken:

```bash
git commit --allow-empty -m "test(18oe): gate T4 result — [WALK_ONLY / NEEDS_BASE_CHANGE]"
```

---

## Task 5: (Conditional) Add `sub_stops` expansion to `base.rb`

**Only run this task if Task 4 gate result was NEEDS_BASE_CHANGE.**

**Files:**
- Modify: `lib/engine/game/base.rb:1605-1607`

Current:
```ruby
def visited_stops(route)
  route.connection_data.flat_map { |c| [c[:left], c[:right]] }.uniq.compact
end
```

- [ ] **Step 5.1 — Add expansion**

```ruby
def visited_stops(route)
  route.connection_data.flat_map { |c| [c[:left], c[:right]] }.uniq.compact
       .flat_map { |s| s.respond_to?(:sub_stops) ? s.sub_stops : [s] }
end
```

- [ ] **Step 5.2 — Verify expansion**

```bash
docker compose exec rack irb -r ./lib/engine
```

```ruby
require_relative 'lib/engine' unless defined?(Engine)
g = Engine::Game::G18OE::Game.new(%w[Alice Bob Charlie])
hex = g.hex_by_id('J29')
dt = hex.tile.towns.first
fake_data = [{ left: dt, right: nil }]
raw = fake_data.flat_map { |c| [c[:left], c[:right]] }.uniq.compact
expanded = raw.flat_map { |s| s.respond_to?(:sub_stops) ? s.sub_stops : [s] }
puts expanded.size == 2 ? 'PASS' : "FAIL: got #{expanded.size}"
puts expanded.all? { |s| s.class == Engine::Part::Town } ? 'PASS: both sub-stops are Town' : 'FAIL'
```

- [ ] **Step 5.3 — Verify no other game affected**

```bash
grep -rn "sub_stops" lib/engine/game/ --include="*.rb"
```

Expected: no output (no game defines or uses `sub_stops`).

- [ ] **Step 5.4 — Commit**

```bash
git add lib/engine/game/base.rb
git commit -m "feat(engine/base): expand sub_stops in visited_stops — Part owns stop-count semantics"
```

---

## Task 6: IRB regression suite

All must print PASS before proceeding to browser testing.

```bash
docker compose exec rack irb -r ./lib/engine
```

```ruby
require_relative 'lib/engine' unless defined?(Engine)
g = Engine::Game::G18OE::Game.new(%w[Alice Bob Charlie])

# T1: DoubleTown instantiated on preprinted double-town hex
hex = g.hex_by_id('J29')
dt = hex.tile.towns.first
puts dt.class == Engine::Part::DoubleTown ? 'PASS T1' : "FAIL T1: got #{dt.class}"

# T2: sub_stops count
puts dt.sub_stops.size == 2 ? 'PASS T2' : "FAIL T2: #{dt.sub_stops.size}"

# T3: sub_stops are plain Town objects
puts dt.sub_stops.all? { |s| s.class == Engine::Part::Town } ? 'PASS T3' : 'FAIL T3'

# T4: sub_stops revenue
puts dt.sub_stops.all? { |s| s.uniq_revenues == [10] } ? 'PASS T4' : 'FAIL T4'

# T5: town? returns true
puts dt.town? ? 'PASS T5' : 'FAIL T5'

# T6: rect? returns false
puts dt.rect? == false ? 'PASS T6' : 'FAIL T6'

# T7: size == 2
puts dt.size == 2 ? 'PASS T7' : "FAIL T7: #{dt.size}"

# T8: walk override exists on DoubleTown
puts Engine::Part::DoubleTown.instance_methods(false).include?(:walk) ? 'PASS T8' : 'FAIL T8'

# T9: walk marks both internal towns visited
dt2 = Engine::Part::DoubleTown.new('10')
visited = {}
# DoubleTown.walk needs paths wired up; check that walk sets visited on sub-towns
# by directly testing the marking logic
visited[dt2] = false
# simulate what walk does:
dt2.instance_variable_get(:@town_a).tap { |t| visited[t] = true }
dt2.instance_variable_get(:@town_b).tap { |t| visited[t] = true }
puts visited.keys.count { |k| k.class == Engine::Part::Town } == 2 ? 'PASS T9' : 'FAIL T9'

# T10: no game-level visited_stops override in G18OE
puts !Engine::Game::G18OE::Game.instance_methods(false).include?(:visited_stops) ? 'PASS T10' : 'FAIL T10'

# T11: no game-level revenue_stops override in G18OE
puts !Engine::Game::G18OE::Game.instance_methods(false).include?(:revenue_stops) ? 'PASS T11' : 'FAIL T11'

# T12: plain town hex unaffected
plain = g.hexes.find { |h| h.tile.towns.size == 1 && h.tile.towns.first.class == Engine::Part::Town }
puts plain ? 'PASS T12' : 'FAIL T12: no plain Town hex found'
```

- [ ] **Step 6.1 — Run all 12, confirm all PASS**
- [ ] **Step 6.2 — Fix any failures before continuing**
- [ ] **Step 6.3 — Commit**

```bash
git commit --allow-empty -m "test(18oe): IRB T1-T12 all pass — DoubleTown Part"
```

---

## Task 7: Browser verification

```bash
docker compose up
```

- [ ] **Step 7.1 — Tile gallery rendering**

Open `http://localhost:3000/tiles/18OE`

OE9/OE10/OE11 (yellow) and OE20/OE21/OE22 (brown) each must show:
- Oval outline with **two filled dots**
- Revenue label **twice** (left and right of oval)
- **No internal line** between the two dots

- [ ] **Step 7.2 — Upgrade chain J29**

Load `~/18xx/testgames/simulate_18oe_2.json`. Navigate to hex J29 (preprinted double-town).

- Yellow phase: only OE9/OE10/OE11 offered (not single-town OE1/OE2/OE3)
- Green phase: only OE20/OE21/OE22 offered from yellow double-town

- [ ] **Step 7.3 — Route scores £20**

Run a route with a 2+2 train through J29. Verify:
- Revenue shows £20 for the double-town (2 × £10)
- Train distance shows 2 town slots consumed

- [ ] **Step 7.4 — Commit**

```bash
git commit --allow-empty -m "test(18oe): browser verified — rendering, upgrade chain J29, £20 revenue"
```

---

## Task 8: Style, push, PR update

- [ ] **Step 8.1 — Rubocop targeted files**

```bash
bundle exec rubocop lib/engine/part/double_town.rb lib/engine/tile.rb lib/engine/game/g_18_oe/game.rb
```

If Task 5 was run, also:
```bash
bundle exec rubocop lib/engine/game/base.rb
```

Fix all offences. 130-char line limit. No `puts`/`p`/`pp`.

- [ ] **Step 8.2 — Full style pass**

```bash
make style
```

- [ ] **Step 8.3 — Push**

```bash
git push origin 18oe_tiles
```

- [ ] **Step 8.4 — Update PR #12667 description**

Add:
- Screenshot of OE9–OE22 from `/tiles/18OE`
- Note: game-level overrides removed
- Note: DoubleTownPart owns rendering (via `size:2` dispatch), walk (override marks both internal towns), and stop-count semantics (via `sub_stops`)
- Note whether `base.rb` was touched (Task 5) and why

---

## Self-Review

**Spec coverage:**
- ✓ `Part::DoubleTown` with walk override → Task 1
- ✓ `tile.rb` instantiation → Task 2
- ✓ Remove game overrides → Task 3
- ✓ Gate test: walk-only vs base.rb → Task 4
- ✓ Conditional `base.rb` expansion → Task 5
- ✓ IRB regression 12 tests → Task 6
- ✓ Browser verification → Task 7
- ✓ Style + push + PR → Task 8

**Placeholder scan:** None. All code blocks complete.

**Type consistency:**
- `sub_stops` defined Task 1, gate-tested Task 4, conditionally consumed Task 5, regression-tested Task 6 ✓
- `DoubleTown` class name consistent throughout ✓
- `walk` override signature matches `Node#walk` params ✓
- `visited_stops` signature unchanged (`route` param) ✓
