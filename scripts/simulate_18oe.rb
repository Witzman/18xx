# frozen_string_literal: true
# 18OE simulation — generates importable hotseat JSON until bank breaks.
# Usage (from project root):
#   docker cp ~/18xx/scripts/simulate_18oe.rb 18xx-rack-1:/18xx/scripts/simulate_18oe.rb
#   docker compose exec -T rack ruby scripts/simulate_18oe.rb 2>/tmp/sim_err.txt > /tmp/sim.json
#   docker cp 18xx-rack-1:/tmp/sim.json ~/18xx/testgames/18oe_sim.json

require_relative '../lib/engine'
require 'json'

# Suppress the engine's DEBUG log output so stdout carries only JSON.
LOGGER.level = Logger::FATAL + 1 # suppress everything including rescue_exception LOGGER.error

PLAYERS    = %w[Alice Bob Charlie].freeze
MAX_STEPS  = 30_000

$stderr.puts '=== 18OE Simulation Starting ==='
game = Engine::Game::G18OE::Game.new(PLAYERS)
raw_actions = []
action_id   = 1

# ---------------------------------------------------------------------------
# Core helper — set id before process_action
# ---------------------------------------------------------------------------
def do_action(game, action, raw_actions, action_id)
  action.id         = action_id
  action.created_at = Time.now.to_i
  game.process_action(action)
  game.maybe_raise!
  raw_actions << action.to_h
  action_id + 1
end

# ---------------------------------------------------------------------------
# BFS through connected hexes to find a path between two hexes
# ---------------------------------------------------------------------------
def bfs_hex_path(connected_hex_set, start_hex, end_hex)
  return [start_hex.id, end_hex.id] if start_hex.neighbors.values.include?(end_hex) &&
                                        connected_hex_set.include?(end_hex)

  visited = { start_hex => true }
  queue   = [[start_hex, [start_hex.id]]]

  until queue.empty?
    cur, path = queue.shift
    next if path.size > 20

    cur.neighbors.values.each do |nb|
      next unless connected_hex_set.include?(nb)
      next if visited[nb]

      new_path = path + [nb.id]
      return new_path if nb == end_hex

      visited[nb] = true
      queue << [nb, new_path]
    end
  end
  nil
end

# ---------------------------------------------------------------------------
# Route finder — pure Ruby BFS, falls back to empty routes (withhold)
# ---------------------------------------------------------------------------
def find_routes(game, entity)
  trains = game.route_trains(entity)
  return [] unless trains.any?

  graph = game.graph_for_entity(entity)
  cnodes = graph.connected_nodes(entity)&.keys || []
  return [] if cnodes.size < 2

  connected_hex_set = graph.connected_hexes(entity)&.keys || []
  return [] if connected_hex_set.empty?

  routes = []

  trains.each do |train|
    break if routes.size >= (game.train_limit(entity) rescue 2)

    best_route   = nil
    best_revenue = 0

    cnodes.combination(2) do |n1, n2|
      next if n1.hex == n2.hex

      hex_path = bfs_hex_path(connected_hex_set, n1.hex, n2.hex)
      next unless hex_path

      begin
        r = Engine::Route.new(game, game.phase, train,
              connection_hexes: [hex_path],
              routes: routes)
        rev = r.revenue
        if rev > best_revenue
          best_revenue = rev
          best_route   = r
        end
      rescue Engine::GameError, StandardError
        next
      end
    end

    routes << best_route if best_route
  end

  routes
rescue StandardError => e
  $stderr.puts "  find_routes error for #{entity.id}: #{e.message}"
  []
end

# ---------------------------------------------------------------------------
# Auction
# ---------------------------------------------------------------------------
def handle_auction(game, entity, step, raw_actions, action_id)
  companies_list = step.instance_variable_get(:@companies) || []
  return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id) if companies_list.empty?

  active_company = nil
  step.instance_eval { active_auction { |co, _| active_company = co } } rescue nil

  if active_company
    min = step.min_bid(active_company)
    if entity.cash >= min
      return do_action(game, Engine::Action::Bid.new(entity, company: active_company, price: min), raw_actions, action_id)
    else
      return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
    end
  end

  cheapest = companies_list.first
  return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id) unless cheapest

  min = step.min_bid(cheapest)
  if step.may_purchase?(cheapest) && entity.cash >= min
    do_action(game, Engine::Action::Bid.new(entity, company: cheapest, price: min), raw_actions, action_id)
  else
    do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# BFS distance from every hex to nearest metro — shared by home_token + track
def sort_hexes_toward_metros(hexes, metro_set)
  return hexes if metro_set.empty?

  dist = {}
  queue = metro_set.map { |m| [m, 0] }
  queue.each { |h, _| dist[h] = 0 }
  until queue.empty?
    hex, d = queue.shift
    hex.neighbors.values.each do |nb|
      next if dist.key?(nb)
      dist[nb] = d + 1
      queue << [nb, d + 1]
    end
  end
  hexes.sort_by { |h| dist.fetch(h, 999) }
end

# ---------------------------------------------------------------------------
# HomeToken — prefer cities closest to a metropolis
# ---------------------------------------------------------------------------
def handle_home_token(game, entity, step, raw_actions, action_id)
  metro_names = (game.class::METROPOLIS_UPGRADE_CHAINS.keys rescue [])
  metro_set   = game.hexes.select { |h| metro_names.include?(h.name) }.to_set

  candidate_hexes = if game.respond_to?(:home_token_locations) && entity.type == :minor
    (game.home_token_locations(entity) rescue [])
  else
    []
  end

  if candidate_hexes.empty?
    coords = entity.respond_to?(:coordinates) ? entity.coordinates : nil
    if coords
      h = game.hex_by_id(coords) rescue nil
      candidate_hexes = [h].compact
    end
  end

  candidate_hexes = sort_hexes_toward_metros(candidate_hexes, metro_set)

  candidate_hexes.each do |hex|
    hex.tile.cities.each do |city|
      begin
        return do_action(
          game,
          Engine::Action::PlaceToken.new(entity, city: city),
          raw_actions, action_id
        )
      rescue StandardError
        next
      end
    end
  end

  # Fallback: any city sorted by metro proximity
  sort_hexes_toward_metros(game.hexes.to_a, metro_set).each do |hex|
    hex.tile.cities.each do |city|
      begin
        return do_action(
          game,
          Engine::Action::PlaceToken.new(entity, city: city),
          raw_actions, action_id
        )
      rescue StandardError
        next
      end
    end
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Track (tile laying) — iterate connected hexes, find first valid tile+rotation
# ---------------------------------------------------------------------------
def handle_track(game, entity, step, raw_actions, action_id)
  return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id) unless
    step.respond_to?(:can_lay_tile?) && (step.can_lay_tile?(entity) rescue false)

  metro_names = (game.class::METROPOLIS_UPGRADE_CHAINS.keys rescue [])
  metro_set   = game.hexes.select { |h| metro_names.include?(h.name) }.to_set
  metro_adj   = metro_set.flat_map { |mh| mh.neighbors.values }.uniq.reject { |h| metro_set.include?(h) }
  other_hexes = game.hexes.reject { |h| metro_set.include?(h) || metro_adj.include?(h) }
  ordered_hexes = metro_set.to_a.shuffle + metro_adj.shuffle + other_hexes.shuffle

  ordered_hexes.each do |hex|
    next unless step.respond_to?(:tracker_available_hex) &&
                (step.tracker_available_hex(entity, hex) rescue nil)

    tiles = step.respond_to?(:potential_tiles) ? (step.potential_tiles(entity, hex) rescue []) : []
    tiles.each do |proto|
      rotations = if step.respond_to?(:legal_tile_rotations)
        (step.legal_tile_rotations(entity, hex, proto.dup) rescue (0..5).to_a)
      else
        (0..5).to_a
      end
      actual = game.tiles.find { |t| t.name == proto.name && t.hex.nil? }
      next unless actual

      terrain_cost = (game.upgrade_cost(hex.tile, hex, entity, entity) rescue 0)
      next if entity.respond_to?(:cash) && entity.cash < terrain_cost

      rotations.each do |rot|
        begin
          return do_action(
            game,
            Engine::Action::LayTile.new(entity, tile: actual, hex: hex, rotation: rot),
            raw_actions, action_id
          )
        rescue StandardError
          next
        end
      end
    end
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Token placement
# ---------------------------------------------------------------------------
def handle_token(game, entity, step, raw_actions, action_id)
  candidates = []
  game.hexes.each do |hex|
    hex.tile.cities.each do |city|
      next unless step.respond_to?(:can_place_token?) && (step.can_place_token?(entity, city) rescue false)

      rev = city.max_revenue rescue (city.revenue.is_a?(Hash) ? city.revenue.values.max : city.revenue.to_i)
      candidates << [city, rev.to_i]
    end
  end

  candidates.sort_by { |_, rev| -rev }.each do |city, _|
    begin
      return do_action(game, Engine::Action::PlaceToken.new(entity, city: city), raw_actions, action_id)
    rescue StandardError
      next
    end
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Dividend
# ---------------------------------------------------------------------------
def handle_dividend(game, entity, step, raw_actions, action_id)
  revenue = step.respond_to?(:total_revenue) ? (step.total_revenue rescue 0) : 0
  types   = step.respond_to?(:dividend_types) ? (step.dividend_types rescue %i[withhold payout]) : %i[withhold payout]

  # Withhold when treasury can't cover cheapest available train — save up to buy trains.
  # This prevents corps from paying out revenue they need for phase-advancing train purchases.
  min_train  = game.depot.min_depot_train
  should_save = min_train && entity.cash < min_train.price

  kind = if revenue.zero?
           'withhold'
         elsif should_save
           'withhold'
         elsif revenue.positive? && types.include?(:payout)
           'payout'
         elsif revenue.positive? && types.include?(:half)
           'half'
         else
           'withhold'
         end

  begin
    do_action(game, Engine::Action::Dividend.new(entity, kind: kind), raw_actions, action_id)
  rescue StandardError
    do_action(game, Engine::Action::Dividend.new(entity, kind: 'withhold'), raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Emergency sell: president sells one share bundle to fund a train
# ---------------------------------------------------------------------------
def handle_emergency_sell(game, entity, step, raw_actions, action_id)
  president = entity.respond_to?(:owner) ? entity.owner : nil
  return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id) unless president

  game.corporations.each do |corp|
    next if corp == entity

    bundles = (game.all_bundles_for_corporation(president, corp) rescue [])
    bundles = bundles.reject { |b| b.presidents_share } rescue []
    bundle  = bundles.min_by(&:num_shares)
    next unless bundle
    next unless (step.can_sell?(president, bundle) rescue false)

    begin
      return do_action(
        game,
        Engine::Action::SellShares.new(president, shares: bundle.shares,
                                        share_price: bundle.share_price,
                                        percent: bundle.percent),
        raw_actions, action_id
      )
    rescue StandardError => e
      $stderr.puts "  emergency sell err #{corp.id}: #{e.message}"
    end
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Buy train — train rush: buy most expensive affordable train to advance phases
# ---------------------------------------------------------------------------
def handle_buy_train(game, entity, step, raw_actions, action_id)
  must_buy = if step.respond_to?(:must_buy_train?)
    (step.must_buy_train?(entity) rescue false)
  elsif game.respond_to?(:must_buy_train?)
    (game.must_buy_train?(entity) rescue false)
  else
    false
  end

  trains = step.respond_to?(:buyable_trains) ? (step.buyable_trains(entity) rescue []) : []
  trains = trains.flatten.compact
  return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id) if trains.empty?

  # Nationals claim rusted trains for free (spend_minmax returns [0,0] — bypass cash check)
  if entity.respond_to?(:type) && entity.type == :national
    rusted = trains.select { |t| t.respond_to?(:rusted) && t.rusted }
    if rusted.any?
      begin
        return do_action(
          game,
          Engine::Action::BuyTrain.new(entity, train: rusted.first, price: 0),
          raw_actions, action_id
        )
      rescue StandardError => e
        $stderr.puts "  national_claim err #{entity.id}: #{e.message}"
      end
    end
  end

  # Prefer most expensive train affordable (advances phases faster)
  target = trains.select { |t| entity.cash >= t.price }.max_by(&:price)
  # Fallback to cheapest when must_buy and can't fully afford anything
  target ||= trains.min_by(&:price) if must_buy

  should_buy = target && (must_buy || entity.cash >= target.price)

  if should_buy
    begin
      return do_action(
        game,
        Engine::Action::BuyTrain.new(entity, train: target, price: target.price),
        raw_actions, action_id
      )
    rescue StandardError => e
      $stderr.puts "  buy_train err #{entity.id}: #{e.message}"
      step_actions = (step.actions(entity) rescue [])
      return handle_emergency_sell(game, entity, step, raw_actions, action_id) if step_actions.include?('sell_shares')
    end
  elsif must_buy
    # Proactive emergency sell when can't afford cheapest
    step_actions = (step.actions(entity) rescue [])
    return handle_emergency_sell(game, entity, step, raw_actions, action_id) if step_actions.include?('sell_shares')
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Discard train (over limit)
# ---------------------------------------------------------------------------
def handle_discard_train(game, entity, raw_actions, action_id)
  train = entity.trains.min_by(&:price)
  if train
    begin
      return do_action(game, Engine::Action::DiscardTrain.new(entity, train: train), raw_actions, action_id)
    rescue StandardError
    end
  end
  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Choose (Golden Bell, SML, etc.)
# ---------------------------------------------------------------------------
def handle_choose(game, entity, step, raw_actions, action_id)
  choices = step.respond_to?(:choices) ? (step.choices rescue {}) : {}
  choices = {} unless choices.respond_to?(:keys)
  choice  = choices.keys.first || 'normal'
  begin
    do_action(game, Engine::Action::Choose.new(entity, choice: choice), raw_actions, action_id)
  rescue StandardError
    do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Par helpers — smart capitalization
# ---------------------------------------------------------------------------

def min_viable_par(corp, game)
  region = game.class::CORPORATIONS_TRACK_RIGHTS[corp.id]
  rights = region ? (game.class::TRACK_RIGHTS_COST[region] || 0) : 40
  needed = rights + 100
  prices = game.stock_market.par_prices.sort_by(&:price)
  prices.find { |p| p.price * 2 >= needed } || prices.last
end

def higher_par(game)
  game.stock_market.par_prices.sort_by(&:price).find { |p| p.price * 2 >= 200 } ||
    game.stock_market.par_prices.sort_by(&:price).last
end

def metro_region_corps(game)
  metro_hexes   = (game.class::METROPOLIS_UPGRADE_CHAINS.keys rescue [])
  metro_regions = game.class::NATIONAL_REGION_HEXES
    .select { |_, hexes| (hexes & metro_hexes).any? }.keys
  game.class::CORPORATIONS_TRACK_RIGHTS
    .select { |_, region| metro_regions.include?(region) }.keys
end

# ---------------------------------------------------------------------------
# Par (Stock Round) — minimum viable capitalization; metro corps get higher
# ---------------------------------------------------------------------------
def handle_par(game, entity, step, raw_actions, action_id, good_corps, good_corp_budget)
  prices = game.stock_market.par_prices.sort_by(&:price)

  # Float minors first — par at £70 (covers worst-case UK/PHS rights £40 + £100)
  entity.companies.each do |company|
    next unless game.company_becomes_minor?(company)

    minor_corp = game.corporations.find { |c| c.name == company.sym }
    next unless minor_corp && !minor_corp.ipoed

    price = prices.find { |p| p.price * 2 >= 140 } || prices.first
    next unless entity.cash >= price.price * 2

    begin
      return do_action(
        game,
        Engine::Action::Par.new(entity, corporation: minor_corp, share_price: price),
        raw_actions, action_id
      )
    rescue Engine::GameError => e
      $stderr.puts "  minor float skip #{minor_corp.id}@#{price.price}: #{e.message}"
    rescue StandardError => e
      $stderr.puts "  minor float err #{minor_corp.id}@#{price.price}: #{e.message}"
    end
  end

  unparred_good  = game.corporations.select { |c| !c.ipoed && c.type == :regional && good_corps.include?(c.id) }
  unparred_other = game.corporations.select { |c| !c.ipoed && c.type == :regional && !good_corps.include?(c.id) }

  (unparred_good.shuffle + unparred_other.shuffle).each do |corp|
    is_good = good_corps.include?(corp.id) && good_corp_budget.fetch(entity.id, 0) > 0
    price   = is_good ? higher_par(game) : min_viable_par(corp, game)
    next unless entity.cash >= price.price * 2

    begin
      result = do_action(
        game,
        Engine::Action::Par.new(entity, corporation: corp, share_price: price),
        raw_actions, action_id
      )
      good_corp_budget[entity.id] = (good_corp_budget.fetch(entity.id, 0) - 1) if is_good
      return result
    rescue Engine::GameError => e
      $stderr.puts "  par skip #{corp.id}@#{price.price}: #{e.message}"
      next
    rescue StandardError => e
      $stderr.puts "  par err #{corp.id}@#{price.price}: #{e.message}"
      next
    end
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Issue shares (OR) — corp sells treasury shares when cash is low
# ---------------------------------------------------------------------------
def handle_issue_shares(game, entity, step, raw_actions, action_id)
  bundles = if step.respond_to?(:issuable_shares)
    (step.issuable_shares(entity) rescue [])
  elsif step.respond_to?(:sellable_bundles)
    (step.sellable_bundles(entity) rescue [])
  else
    []
  end
  return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id) if bundles.empty?

  cheapest_train_price = game.depot.upcoming.first&.price || 200
  return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id) if entity.cash >= cheapest_train_price

  bundle = bundles.min_by(&:num_shares)
  begin
    do_action(game, Engine::Action::SellShares.new(entity, shares: bundle.shares,
                   share_price: bundle.share_price, percent: bundle.percent), raw_actions, action_id)
  rescue StandardError => e
    $stderr.puts "  issue err #{entity.id}: #{e.message}"
    do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Buy shares (SR) — own corps first; checks both IPO and pool
# ---------------------------------------------------------------------------
def handle_buy_shares(game, entity, raw_actions, action_id)
  own_corps   = game.corporations.select { |c| c.ipoed && (c.president?(entity) rescue false) }.shuffle
  other_corps = game.corporations.select { |c| c.ipoed && !(c.president?(entity) rescue false) }.shuffle
  (own_corps + other_corps).each do |corp|
    ipo_shares  = corp.shares_of(corp) rescue []
    pool_shares = game.share_pool.shares_by_corporation[corp] || []
    (ipo_shares + pool_shares).each do |share|
      bundle = share.to_bundle rescue nil
      next unless bundle && entity.cash >= bundle.price

      begin
        return do_action(
          game,
          Engine::Action::BuyShares.new(entity,
            shares: bundle.shares,
            share_price: bundle.share_price,
            percent: bundle.percent),
          raw_actions, action_id
        )
      rescue StandardError
        next
      end
    end
  end
  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Convert — player triggers regional→major conversion (BuySellParShares step)
# ---------------------------------------------------------------------------
def handle_convert(game, entity, step, raw_actions, action_id)
  corp_to_convert = if entity.corporation?
    entity
  else
    game.corporations.find { |c| step.respond_to?(:can_convert?) && (step.can_convert?(c, entity) rescue false) }
  end

  unless corp_to_convert
    return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
  end

  begin
    do_action(game, Engine::Action::Convert.new(corp_to_convert), raw_actions, action_id)
  rescue StandardError => e
    $stderr.puts "  convert err #{corp_to_convert.id}: #{e.message}"
    do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
  end
end

# ---------------------------------------------------------------------------
# Merge — minor into a major/national
# ---------------------------------------------------------------------------
def handle_merge(game, entity, step, raw_actions, action_id)
  minor   = step.respond_to?(:mergeable_entity)  ? (step.mergeable_entity  rescue nil) : nil
  targets = step.respond_to?(:mergeable_entities) ? (step.mergeable_entities rescue []) : []
  major   = targets.first

  if minor && major
    begin
      return do_action(
        game,
        Engine::Action::Merge.new(minor, corporation: major),
        raw_actions, action_id
      )
    rescue StandardError => e
      $stderr.puts "  merge err #{minor.id}→#{major.id}: #{e.message}"
    end
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# ConvertToNational — player in nationals_formation_queue picks a major to convert
# ---------------------------------------------------------------------------
def handle_convert_to_national(game, entity, step, raw_actions, action_id)
  # Pass until phase 8 — majors must remain to buy L5–L8 trains and advance phases.
  # Nationals cannot buy depot trains; premature conversion stalls phase progression.
  # Phase 8 also has nationals_can_form; convert there to exercise national mechanics.
  phase_num = game.phase.name.to_i rescue 0
  if phase_num < 8
    return do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
  end

  player = entity
  eligible = game.corporations.select { |c| c.type == :major && c.president?(player) }

  eligible.each do |major|
    begin
      return do_action(game, Engine::Action::Convert.new(major), raw_actions, action_id)
    rescue StandardError => e
      $stderr.puts "  nat_convert err #{major.id}: #{e.message}"
    end
  end

  do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
end

# ---------------------------------------------------------------------------
# Main simulation loop
# ---------------------------------------------------------------------------
bank_broken             = false
step_count              = 0
last_round_class        = nil
acted_this_round        = Hash.new(0)
last_entity             = nil
last_step_class         = nil
stuck_count             = 0
cert_bought_pre_convert = {}
GOOD_CORPS_PER_PLAYER   = 2
good_corps              = metro_region_corps(game)
good_corp_budget        = Hash.new(GOOD_CORPS_PER_PLAYER)

until game.finished || bank_broken || step_count >= MAX_STEPS
  step_count += 1
  entity = game.current_entity
  step   = game.active_step
  break unless step

  round_class = game.round.class
  if round_class != last_round_class
    acted_this_round.clear
    cert_bought_pre_convert.clear if game.round.is_a?(Engine::Round::Stock)
    last_round_class = round_class
  end

  available = begin
    step.actions(entity)
  rescue StandardError => e
    $stderr.puts "  actions() err: #{e.message}"
    ['pass']
  end

  $stderr.print "\r[#{action_id}] #{round_class.to_s.split('::').last} #{entity.id} #{available.first(3).inspect} bank=#{game.bank.cash}   "

  # Stuck-loop guard
  if entity == last_entity && step.class == last_step_class
    stuck_count += 1
    if stuck_count > 20
      if available.include?('pass')
        $stderr.puts "\nSTUCK [#{action_id}] #{entity.id} #{step.class} — forcing pass"
        action_id = do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
        stuck_count = 0
        next
      else
        $stderr.puts "\nSTUCK [#{action_id}] #{entity.id} #{step.class} available=#{available.inspect} — no pass available, aborting"
        break
      end
    end
  else
    stuck_count = 0
  end
  last_entity     = entity
  last_step_class = step.class

  in_sr      = game.round.is_a?(Engine::Round::Stock)
  entity_key = "#{entity.id}_#{step.class}"
  force_pass = in_sr && acted_this_round[entity_key] >= 1 && available.include?('pass') &&
               !available.include?('convert')

  begin
    action_id = if step.is_a?(Engine::Game::G18OE::Step::ConvertToNational)
      handle_convert_to_national(game, entity, step, raw_actions, action_id)
    elsif force_pass
      do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
    elsif available.include?('bid')
      handle_auction(game, entity, step, raw_actions, action_id)
    elsif available.include?('place_token') && step.is_a?(Engine::Step::HomeToken)
      handle_home_token(game, entity, step, raw_actions, action_id)
    elsif available.include?('sell_shares') && entity.respond_to?(:corporation?) && entity.corporation? &&
          !available.include?('buy_train')
      handle_issue_shares(game, entity, step, raw_actions, action_id)
    elsif available.include?('lay_tile')
      handle_track(game, entity, step, raw_actions, action_id)
    elsif available.include?('place_token')
      handle_token(game, entity, step, raw_actions, action_id)
    elsif available.include?('run_routes')
      routes = find_routes(game, entity)
      do_action(game, Engine::Action::RunRoutes.new(entity, routes: routes), raw_actions, action_id)
    elsif available.include?('dividend')
      handle_dividend(game, entity, step, raw_actions, action_id)
    elsif available.include?('buy_train')
      handle_buy_train(game, entity, step, raw_actions, action_id)
    elsif available.include?('discard_train')
      handle_discard_train(game, entity, raw_actions, action_id)
    elsif available.include?('convert') && available.include?('buy_shares') &&
          !cert_bought_pre_convert[entity.id]
      cert_bought_pre_convert[entity.id] = true
      acted_this_round[entity_key] += 1
      handle_buy_shares(game, entity, raw_actions, action_id)
    elsif available.include?('convert')
      handle_convert(game, entity, step, raw_actions, action_id)
    elsif available.include?('merge')
      handle_merge(game, entity, step, raw_actions, action_id)
    elsif available.include?('choose')
      handle_choose(game, entity, step, raw_actions, action_id)
    elsif available.include?('par')
      handle_par(game, entity, step, raw_actions, action_id, good_corps, good_corp_budget)
    elsif available.include?('buy_shares')
      acted_this_round[entity_key] += 1
      handle_buy_shares(game, entity, raw_actions, action_id)
    else
      do_action(game, Engine::Action::Pass.new(entity), raw_actions, action_id)
    end
  rescue StandardError => e
    $stderr.puts "\nFATAL [#{action_id}] #{entity.id} #{step.class}: #{e.message}"
    $stderr.puts e.backtrace.first(3).join("\n")
    break
  end

  bank_broken = game.bank.cash <= 0
end

nationals_formed = game.corporations.count { |c| c.type == :national } rescue 0
majors_formed    = game.corporations.count { |c| c.type == :major   } rescue 0
merges_done      = raw_actions.count { |a| a['type'] == 'merge' }
$stderr.puts "\n=== Done: #{raw_actions.size} actions | bank=£#{game.bank.cash} | phase=#{game.phase.name} | " \
             "reg→major=#{majors_formed + nationals_formed} | major→national=#{nationals_formed} | " \
             "merges=#{merges_done} | finished=#{game.finished} ==="

status = game.finished ? 'finished' : 'active'
result = {
  'status'      => status,
  'id'          => 'hs_testsim_1779376620',
  'players'     => PLAYERS.map { |p| { 'name' => p } },
  'title'       => '18OE',
  'description' => '3-player simulation to bank break',
  'mode'        => 'hotseat',
  'user'        => { 'id' => 0, 'name' => 'You' },
  'created_at'  => '2026-05-21',
  'loaded'      => false,
  'settings'    => {},
  'actions'     => raw_actions,
}

puts result.to_json
