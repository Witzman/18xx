# frozen_string_literal: true
# 18OE game simulation — generates importable JSON up to first 8+8 purchase.
# Run: ruby simulate_18oe.rb > 18oe_sim.json

require_relative 'lib/engine'
require 'json'

PLAYERS = %w[Alice Bob Charlie].freeze
MAX_STEPS = 20_000
TARGET_TRAIN = '8+8'

$stderr.puts '=== 18OE Simulation Starting ==='

game = Engine::Game::G18OE::Game.new(PLAYERS)
raw_actions = []
action_id = 1

# ---------------------------------------------------------------------------
# Helper: wrap process_action and record the serialized action
# ---------------------------------------------------------------------------
def do_action(game, action, raw_actions, action_id)
  action.id = action_id
  action.created_at = Time.now.to_i
  game.process_action(action)
  raw_actions << action.to_h
  action_id + 1
rescue StandardError => e
  $stderr.puts "ACTION ERROR [#{action_id}] #{action.class}: #{e.message}"
  $stderr.puts "  entity=#{action.entity} round=#{game.round.class}"
  raise
end

def pass!(entity, game, raw_actions, action_id)
  a = Engine::Action::Pass.new(entity)
  do_action(game, a, raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Auction helpers
# ---------------------------------------------------------------------------
def handle_auction(game, entity, step, raw_actions, action_id)
  companies_list = step.instance_variable_get(:@companies)
  return pass!(entity, game, raw_actions, action_id) if companies_list.nil? || companies_list.empty?

  # If there's an active auction, bid if cheapest bidder, else pass
  active_company = nil
  step.instance_eval do
    active_auction { |company, _bids| active_company = company }
  end

  if active_company
    # We're in a mini-auction — bid min or pass
    min = step.min_bid(active_company)
    if entity.cash >= min
      return do_action(game, Engine::Action::Bid.new(entity, company: active_company, price: min), raw_actions, action_id)
    else
      return pass!(entity, game, raw_actions, action_id)
    end
  end

  # Normal turn: buy cheapest available company if affordable
  cheapest = companies_list.first
  return pass!(entity, game, raw_actions, action_id) unless cheapest

  min = step.min_bid(cheapest)
  if step.may_purchase?(cheapest) && entity.cash >= min
    do_action(game, Engine::Action::Bid.new(entity, company: cheapest, price: min), raw_actions, action_id)
  else
    pass!(entity, game, raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Tile laying helpers
# ---------------------------------------------------------------------------
def handle_track(game, entity, step, raw_actions, action_id)
  # Try to find a valid tile lay
  lays = step.respond_to?(:legal_tile_lays) ? step.legal_tile_lays(entity) : []

  if lays.empty?
    # Try to find manually via hex iterator
    game.hexes.each do |hex|
      next unless step.respond_to?(:can_lay_tile?) && step.can_lay_tile?(entity) rescue next

      hex.tile.upgrades.each do |upgrade|
        tile_sym = upgrade.tiles.first rescue nil
        next unless tile_sym

        tile = game.tile_by_id("#{tile_sym}-0") rescue nil
        next unless tile

        (0..5).each do |rot|
          begin
            action = Engine::Action::LayTile.new(entity, tile: tile, hex: hex, rotation: rot)
            game.process_action(action)
            h = action.to_h
            raw_actions << h.merge('id' => action_id, 'original_id' => action_id)
            return action_id + 1
          rescue StandardError
            next
          end
        end
      end
    end
    # Can't lay tile — pass this step
    pass!(entity, game, raw_actions, action_id)
  else
    lay = lays.first
    begin
      action = Engine::Action::LayTile.new(entity, tile: lay[:tile], hex: lay[:hex], rotation: lay[:rotation] || 0)
      do_action(game, action, raw_actions, action_id)
    rescue StandardError
      pass!(entity, game, raw_actions, action_id)
    end
  end
end

# ---------------------------------------------------------------------------
# Token placement helpers
# ---------------------------------------------------------------------------
def handle_token(game, entity, step, raw_actions, action_id)
  # Find a city where we can place a token
  cities = game.hexes.flat_map { |h| h.tile.cities }.select { |c|
    step.respond_to?(:can_place_token?) && step.can_place_token?(entity, c) rescue false
  }

  if cities.empty?
    pass!(entity, game, raw_actions, action_id)
  else
    city = cities.first
    token = entity.next_token
    if token
      begin
        do_action(game, Engine::Action::PlaceToken.new(entity, city: city, tokened: city), raw_actions, action_id)
      rescue StandardError
        pass!(entity, game, raw_actions, action_id)
      end
    else
      pass!(entity, game, raw_actions, action_id)
    end
  end
end

# ---------------------------------------------------------------------------
# Route running: try graph-based discovery, fall back to empty routes
# ---------------------------------------------------------------------------
def handle_routes(game, entity, raw_actions, action_id)
  # Try to find simple routes using graph
  routes = []
  begin
    trains = game.route_trains(entity)
    if trains.any?
      graph = game.graph_for_entity(entity)
      nodes_hash = graph.connected_nodes(entity)
      if nodes_hash && nodes_hash.size >= 2
        nodes = nodes_hash.keys.sort_by { |n| n.tokened_by?(entity) ? 0 : 1 }
        # Try a single 2-stop route with the first train
        train = trains.first
        # Look for a path between first two nodes
        # Use connection_hexes approach — find hexes in between
        found = false
        nodes.combination(2) do |n1, n2|
          break if found
          hex1 = n1.hex
          hex2 = n2.hex
          next if hex1 == hex2

          # Try direct adjacency
          if hex1.neighbors.values.include?(hex2)
            begin
              route = Engine::Route.new(
                game,
                game.phase,
                train,
                connection_hexes: [[hex1.id, hex2.id]],
                routes: routes,
              )
              route.revenue # validate
              routes = [route]
              found = true
            rescue StandardError
              # not valid
            end
          end

          unless found
            # Try 3-hop routes
            hex1.neighbors.each do |_dir, mid_hex|
              break if found
              if mid_hex.neighbors.values.include?(hex2)
                begin
                  route = Engine::Route.new(
                    game,
                    game.phase,
                    train,
                    connection_hexes: [[hex1.id, mid_hex.id, hex2.id]],
                    routes: routes,
                  )
                  route.revenue
                  routes = [route]
                  found = true
                rescue StandardError
                  nil
                end
              end
            end
          end
        end
      end
    end
  rescue StandardError => e
    $stderr.puts "  Route find error: #{e.message}"
    routes = []
  end

  do_action(game, Engine::Action::RunRoutes.new(entity, routes: routes), raw_actions, action_id)
rescue StandardError
  # last resort: empty routes
  do_action(game, Engine::Action::RunRoutes.new(entity, routes: []), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Dividend
# ---------------------------------------------------------------------------
def handle_dividend(game, entity, step, raw_actions, action_id)
  types = step.respond_to?(:dividend_types) ? step.dividend_types : %i[withhold payout]
  # Prefer payout if revenue > 0, else withhold
  revenue = step.respond_to?(:total_revenue) ? step.total_revenue : 0
  kind = if revenue.positive? && types.include?(:payout)
           'payout'
         elsif revenue.positive? && types.include?(:half)
           'half'
         else
           'withhold'
         end
  do_action(game, Engine::Action::Dividend.new(entity, kind: kind), raw_actions, action_id)
rescue StandardError
  do_action(game, Engine::Action::Dividend.new(entity, kind: 'withhold'), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Train purchase
# ---------------------------------------------------------------------------
def handle_buy_train(game, entity, step, raw_actions, action_id)
  # Must buy if no trains
  must_buy = game.respond_to?(:must_buy_train?) && game.must_buy_train?(entity)
  trains_available = step.respond_to?(:buyable_trains) ? step.buyable_trains(entity) : game.depot.available(entity)

  if trains_available.empty?
    return pass!(entity, game, raw_actions, action_id)
  end

  # Always buy if must_buy or entity has no trains
  if must_buy || entity.trains.empty?
    cheapest = trains_available.min_by(&:price)
    if cheapest && entity.cash >= cheapest.price
      return do_action(
        game,
        Engine::Action::BuyTrain.new(entity, train: cheapest, price: cheapest.price),
        raw_actions, action_id
      )
    elsif cheapest && must_buy
      # Try emergency buy — sell from bank pool is handled by engine
      # Try paying president's cash
      if entity.cash + (entity.owner&.cash || 0) >= cheapest.price
        return do_action(
          game,
          Engine::Action::BuyTrain.new(entity, train: cheapest, price: cheapest.price),
          raw_actions, action_id
        )
      end
    end
  end

  pass!(entity, game, raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Par / Share buying
# ---------------------------------------------------------------------------
def handle_par(game, entity, step, raw_actions, action_id)
  # Par lowest-price unpared corporation the player can afford
  pars = step.respond_to?(:get_par_prices) ? nil : nil
  corp = game.corporations.find { |c| !c.ipoed? && %i[regional major].include?(c.type) } rescue nil
  unless corp
    return pass!(entity, game, raw_actions, action_id)
  end

  prices = game.stock_market.par_prices.sort_by(&:price)
  prices.each do |price|
    if entity.cash >= price.price * 2
      begin
        return do_action(game, Engine::Action::Par.new(entity, corporation: corp, share_price: price), raw_actions, action_id)
      rescue StandardError
        next
      end
    end
  end
  pass!(entity, game, raw_actions, action_id)
end

def handle_buy_shares(game, entity, step, raw_actions, action_id)
  # Try to buy a share in any floated corporation
  bundles = game.corporations.flat_map { |c|
    next [] unless c.ipoed?
    game.share_pool.shares_by_corporation[c]&.map(&:to_bundle) || []
  }.compact.select { |b| entity.cash >= b.price rescue false }

  if bundles.any?
    bundle = bundles.min_by(&:price)
    begin
      return do_action(game, Engine::Action::BuyShares.new(entity, shares: bundle.shares, share_price: bundle.share_price, percent: bundle.percent), raw_actions, action_id)
    rescue StandardError
      nil
    end
  end
  pass!(entity, game, raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Hochberg placement: pass (approve removal)
# ---------------------------------------------------------------------------
def handle_hochberg(game, entity, step, raw_actions, action_id)
  pass!(entity, game, raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Choose action (Golden Bell, SML, etc.)
# ---------------------------------------------------------------------------
def handle_choose(game, entity, step, raw_actions, action_id)
  choices = step.respond_to?(:choices) ? step.choices : {}
  choice = choices.keys.first
  if choice
    do_action(game, Engine::Action::Choose.new(entity, choice: choice), raw_actions, action_id)
  else
    pass!(entity, game, raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Choose ability (track rights zone selection, D-token, etc.)
# ---------------------------------------------------------------------------
def handle_choose_ability(game, entity, step, raw_actions, action_id)
  # For track rights: pick first available zone
  abilities = step.respond_to?(:abilities) ? (step.abilities(entity) rescue []) : []
  ability = abilities.first
  if ability && ability.respond_to?(:choices)
    choice = ability.choices.first
    do_action(game, Engine::Action::ChooseAbility.new(entity, ability: ability, choice: choice), raw_actions, action_id)
  else
    pass!(entity, game, raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Discard train (if over limit)
# ---------------------------------------------------------------------------
def handle_discard_train(game, entity, step, raw_actions, action_id)
  train = entity.trains.min_by(&:price)
  if train
    do_action(game, Engine::Action::DiscardTrain.new(entity, train: train), raw_actions, action_id)
  else
    pass!(entity, game, raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Main simulation loop
# ---------------------------------------------------------------------------
first_8_8_bought = false
step_count = 0
# Track non-pass actions per (entity, round) to prevent infinite loops
acted_entities = Hash.new(0)
last_round_class = nil

until game.finished || first_8_8_bought || step_count > MAX_STEPS
  step_count += 1
  entity = game.current_entity
  step = game.active_step
  break unless step

  # Reset tracking when round changes
  if game.round.class != last_round_class
    acted_entities.clear
    last_round_class = game.round.class
  end

  available = begin
    step.actions(entity)
  rescue StandardError => e
    $stderr.puts "actions() error: #{e.message}"
    ['pass']
  end

  $stderr.print "\r[#{action_id}] #{game.round.class.to_s.split('::').last} #{entity} #{available.first(3).inspect}   "

  # In stock round: each player gets 1 non-pass action then must pass
  in_stock_round = game.round.is_a?(Engine::Round::Stock)
  entity_key = "#{entity.id}_#{step.class}"
  force_pass = in_stock_round && acted_entities[entity_key] >= 1 && available.include?('pass')

  begin
    action_id = if force_pass
      pass!(entity, game, raw_actions, action_id)
    else
      case
      when available.include?('bid')
        handle_auction(game, entity, step, raw_actions, action_id)
      when available.include?('par')
        acted_entities[entity_key] += 1
        handle_par(game, entity, step, raw_actions, action_id)
      when available.include?('buy_shares') && !available.include?('sell_shares')
        acted_entities[entity_key] += 1
        handle_buy_shares(game, entity, step, raw_actions, action_id)
      when available.include?('lay_tile')
        handle_track(game, entity, step, raw_actions, action_id)
      when available.include?('place_token')
        handle_token(game, entity, step, raw_actions, action_id)
      when available.include?('run_routes')
        handle_routes(game, entity, raw_actions, action_id)
      when available.include?('dividend')
        handle_dividend(game, entity, step, raw_actions, action_id)
      when available.include?('buy_train')
        handle_buy_train(game, entity, step, raw_actions, action_id)
      when available.include?('choose')
        handle_choose(game, entity, step, raw_actions, action_id)
      when available.include?('choose_ability')
        handle_choose_ability(game, entity, step, raw_actions, action_id)
      when available.include?('discard_train')
        handle_discard_train(game, entity, step, raw_actions, action_id)
      when available.include?('sell_shares')
        pass!(entity, game, raw_actions, action_id)
      else
        pass!(entity, game, raw_actions, action_id)
      end
    end
  rescue StandardError => e
    $stderr.puts "\nFATAL at action #{action_id}: #{e.message}"
    $stderr.puts e.backtrace.first(5).join("\n")
    break
  end

  # Check if first 8+8 was bought by a corporation
  if game.trains.any? { |t| t.name == TARGET_TRAIN && t.owner.respond_to?(:corporation?) && t.owner.corporation? rescue false }
    first_8_8_bought = true
  end
end

$stderr.puts "\n=== Done: #{raw_actions.size} actions, finished=#{game.finished}, 8+8=#{first_8_8_bought} ==="

# Build output JSON
result = {
  'status' => game.finished ? 'finished' : 'active',
  'id' => 'hs_simulate_1779376620',
  'players' => PLAYERS.map { |p| { 'name' => p } },
  'title' => '18OE',
  'description' => '18OE simulation',
  'mode' => 'hotseat',
  'user' => { 'id' => 0, 'name' => 'You' },
  'created_at' => '2026-05-21',
  'loaded' => false,
  'settings' => {},
  'actions' => raw_actions,
}

puts result.to_json
