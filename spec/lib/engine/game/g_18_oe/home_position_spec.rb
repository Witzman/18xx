# frozen_string_literal: true

require 'spec_helper'
require_relative 'helpers'

describe 'G18OE metropolis home position (§11.1.9)' do
  include G18OESpecHelpers

  let(:game) { new_game }
  let(:player) { game.players.first }

  def metropolis!(hex_id)
    hex = game.hex_by_id(hex_id)
    hex.lay(game.tiles.find { |t| t.name == 'OE4' && !t.hex })
    hex
  end

  def pending_home(round, corporation)
    expect(round.active_step).to be_a(Engine::Step::HomeToken)
    expect(round.active_step.current_entity).to eq(corporation)
    round.active_step
  end

  def thin_treasury!(corporation)
    corporation.spend(corporation.cash - 20, game.bank)
  end

  def choose(round, corporation, hex, index)
    act!(round, Engine::Action::PlaceToken.new(corporation, city: hex.tile.cities[index], slot: 0))
  end

  def allowed(round, corporation, hex)
    step = pending_home(round, corporation)
    hex.tile.cities.each_index.select { |index| step.pass_city_ok?(corporation, hex.tile.cities[index]) }
  end

  it 'refuses the position that needs the green tile while another does not (SB)' do
    hex = metropolis!('R55')
    round = stock_round!(game)
    sb = start_regional!(game, 'SB', player)
    thin_treasury!(sb)
    pending_home(round, sb)

    expect { choose(round, sb, hex, 0) }.to raise_error(Engine::GameError, /Right-of-Way/)
    expect(hex.tile.cities[0].tokened_by?(sb)).to be(false)
  end

  it 'allows the other positions and accepts one of them (SB)' do
    hex = metropolis!('R55')
    round = stock_round!(game)
    sb = start_regional!(game, 'SB', player)
    thin_treasury!(sb)

    expect(allowed(round, sb, hex)).to eq([1, 2])
    choose(round, sb, hex, 2)
    expect(hex.tile.cities[2].tokened_by?(sb)).to be(true)
  end

  it 'applies to MSP in C74 as well' do
    hex = metropolis!('C74')
    round = stock_round!(game)
    msp = start_regional!(game, 'MSP', player)
    thin_treasury!(msp)

    expect(allowed(round, msp, hex)).to eq([0])
    expect { choose(round, msp, hex, 1) }.to raise_error(Engine::GameError, /Right-of-Way/)
    choose(round, msp, hex, 0)
    expect(hex.tile.cities[0].tokened_by?(msp)).to be(true)
  end

  it 'lets the president of the floated SB choose when another railroad lays the metropolis tile' do
    sb = start_regional!(game, 'SB', player)
    thin_treasury!(sb)
    lnwr = start_major!(game, 'LNWR', game.players.last)
    round = enter_round!(game, game.operating_round(1))
    round.next_entity! until round.current_entity == lnwr
    step = round_step(round, Engine::Game::G18OE::Step::Track)
    hex = game.hex_by_id('R55')
    old_tile = hex.tile
    hex.lay(game.tiles.find { |t| t.name == 'OE4' && !t.hex })
    step.update_token!(Struct.new(:hex).new(hex), lnwr, hex.tile, old_tile)
    game.graph.clear
    round.clear_cache!

    expect(hex.tile.cities.flat_map(&:tokens).compact).to be_empty
    expect(round.active_step).to be_a(Engine::Step::HomeToken)
    expect(round.active_step.current_entity).to eq(sb)
    expect(sb.owner).not_to eq(lnwr.owner)
    expect(game.active_players).to eq([sb.owner])
    expect(allowed(round, sb, hex)).to eq([1, 2])
    expect { choose(round, sb, hex, 0) }.to raise_error(Engine::GameError, /Right-of-Way/)
    expect { choose(round, lnwr, hex, 1) }.to raise_error(Engine::GameError)

    choose(round, sb, hex, 1)

    expect(hex.tile.cities[1].tokened_by?(sb)).to be(true)
    expect(round.active_step).to be_a(Engine::Game::G18OE::Step::Track)
    expect(round.current_entity).to eq(lnwr)
  end

  it 'places the deferred home token of a regional with an empty treasury at no further cost' do
    hex = metropolis!('C74')
    round = stock_round!(game)
    msp = start_regional!(game, 'MSP', player)
    msp.spend(msp.cash, game.bank)

    expect(allowed(round, msp, hex)).not_to be_empty
    choose(round, msp, hex, 0)

    expect(hex.tile.cities[0].tokened_by?(msp)).to be(true)
    expect(msp.cash).to eq(0)
  end

  it 'does not charge the deferred home token a second time' do
    hex = metropolis!('C74')
    round = stock_round!(game)
    msp = start_regional!(game, 'MSP', player)
    thin_treasury!(msp)

    expect { choose(round, msp, hex, 0) }.not_to(change { msp.cash })
  end

  it 'leaves every position open when yellow track reaches a stop from each of them' do
    hex = metropolis!('R55')
    round = stock_round!(game)
    sb = start_regional!(game, 'SB', player)

    expect(allowed(round, sb, hex)).to eq([0, 1, 2])
  end

  it 'leaves the choice free when every position needs the green tile' do
    hex = metropolis!('R55')
    allow(game).to receive(:right_of_way_home_position_needed?).and_return(true)

    expect(game.home_position_cities(game.corporation_by_id('SB'), hex)).to eq(hex.tile.cities)
  end

  it 'does not restrict the choice in the two-player game' do
    two_player = new_game(%w[a b])
    hex = two_player.hex_by_id('R55')
    hex.lay(two_player.tiles.find { |t| t.name == 'OE4' && !t.hex })

    expect(two_player.home_position_cities(two_player.corporation_by_id('SB'), hex)).to eq(hex.tile.cities)
  end
end
