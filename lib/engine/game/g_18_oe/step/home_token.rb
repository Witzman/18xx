# frozen_string_literal: true

require_relative '../../../step/home_token'
require_relative 'home_position'

module Engine
  module Game
    module G18OE
      module Step
        class HomeToken < Engine::Step::HomeToken
          include HomePosition

          def process_place_token(action)
            check_home_position!(action)
            minor = action.entity.type == :minor
            hex = action.city.hex
            if minor
              region = @game.region_for_hex(hex)

              raise GameError, "Region #{region} is not available" unless @game.region_available?(region)

              token.price = @game.track_rights_cost(region)
              @game.claim_region!(action.entity, region)
            end

            super

            return unless minor

            @game.fulfill_patronage!(action.entity, hex, lowest: true)
          end
        end
      end
    end
  end
end
