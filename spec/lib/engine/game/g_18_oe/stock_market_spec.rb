# frozen_string_literal: true

require 'spec_helper'
require_relative 'helpers'

describe 'G18OE stock market grid of the Info Board (§4, §4.4)' do
  include G18OESpecHelpers

  let(:game) { new_game }
  let(:market) { game.stock_market }
  let(:board_rows) do
    [
      [nil, nil, nil, 110, 120, 135, 150, 165, 180, 200, 225, 250, 280, 310, 350, 390, 440, 490, 550],
      [nil, nil, 90, 100, 110, 120, 135, 150, 165, 180, 200, 225, 250, 280, 310, 350, 390, 440, 490],
      [nil, 75, 80, 90, 100, 110, 120, 135, 150, 165, 180, 200, 225, 250, 280, 310],
      [65, 70, 75, 80, 90, 100, 110, 120, 135, 150, 165, 180, 200],
      [60, 65, 70, 75, 80, 90, 100, 110, 120, 135, 150],
      [55, 60, 65, 70, 75, 80, 90, 100, 110],
      [50, 55, 60, 65, 70, 75, 80],
      [40, 50, 55, 60, 65, 70],
      [30, 40, 50, 55, 60],
    ]
  end

  def price(coordinates)
    market.share_price(coordinates)&.price
  end

  it 'has the nine rows of the printed board, cell by cell' do
    expect(market.market.map { |row| row.map { |sp| sp&.price } }).to eq(board_rows)
  end

  it 'puts the major par values in column 4 and the regional par values in column 2' do
    majors = market.market.flatten.compact.select { |sp| sp.type == :convert_range }
    expect(majors.map { |sp| [sp.price, sp.coordinates[1]] }).to eq([[120, 4], [110, 4], [100, 4], [90, 4], [80, 4], [75, 4]])
    regionals = market.par_prices.map { |sp| [sp.price, sp.coordinates[1]] }
    expect(regionals).to eq([[90, 2], [80, 2], [75, 2], [70, 2], [65, 2], [60, 2]])
  end

  it 'moves DOWN one row and does not move where nothing lies below' do
    expect(price(market.down(nil, [3, 4]))).to eq(80)
    expect(market.down(nil, [8, 0])).to eq([8, 0])
    expect(price(market.down(nil, [8, 4]))).to eq(60)
  end

  it 'moves DOWN to the £30 row' do
    expect(price(market.down(nil, [7, 0]))).to eq(30)
    expect(price(market.down(nil, [7, 3]))).to eq(55)
  end

  it 'moves LEFT one field and DOWN at the left edge' do
    expect(price(market.left(nil, [3, 5]))).to eq(90)
    expect(price(market.left(nil, [0, 3]))).to eq(100)
    expect(price(market.left(nil, [3, 0]))).to eq(60)
    expect(price(market.left(nil, [7, 1]))).to eq(40)
  end

  it 'moves RIGHT one field and UP at the right edge' do
    expect(price(market.right(nil, [4, 4]))).to eq(90)
    expect(price(market.right(nil, [5, 8]))).to eq(120)
    expect(price(market.right(nil, [8, 3]))).to eq(60)
    expect(price(market.right(nil, [8, 4]))).to eq(65)
  end

  it 'moves UP, and RIGHT where no field lies above (top row and the stepped left edge)' do
    expect(price(market.up(nil, [3, 4]))).to eq(100)
    expect(price(market.up(nil, [0, 4]))).to eq(135)
    expect(price(market.up(nil, [1, 2]))).to eq(100)
    expect(price(market.up(nil, [2, 1]))).to eq(80)
    expect(price(market.up(nil, [3, 0]))).to eq(70)
    expect(price(market.up(nil, [4, 0]))).to eq(65)
  end

  it 'moves RIGHT off the end of each row UP' do
    [[1, 18], [2, 15], [3, 12], [4, 10], [5, 8], [6, 6], [7, 5]].each do |row, col|
      expect(market.right(nil, [row, col])).to eq([row - 1, col])
    end
  end
end
