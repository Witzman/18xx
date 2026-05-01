# frozen_string_literal: true

require_relative '../../../game'

module Engine
  module Game
    module G18OE
      class Game < Game::Base
        # Existing code ...

        # Override stock price movement according to 18OE rules
        # - Minors & Regionals: no movement
        # - Majors & Nationals:
        #   * revenue >= share price -> move right
        #   * revenue between 0 and share price -> no move
        #   * revenue = 0 -> move left
        def change_share_price(entity, revenue)
          return if entity.minor? || entity.type == :regional

          share_price = entity.share_price.price

          case
          when revenue >= share_price
            @stock_market.move_right(entity)
          when revenue.zero?
            @stock_market.move_left(entity)
          end
        end
      end
    end
  end
end
