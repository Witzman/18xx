# frozen_string_literal: true

require_relative '../../../step/home_token'

module Engine
  module Game
    module G18OE
      module Step
        module HomePosition
          def pass_city_ok?(_entity, city)
            corporation = token.corporation
            return true if !@game.metropolis_hex?(city.hex) || !corporation.corporation?

            @game.home_position_cities(corporation, city.hex).include?(city)
          end

          def process_place_token(action)
            home = token
            price = home.price
            home.price = 0 unless home.corporation.type == :minor
            super
          ensure
            home.price = price if home
          end

          def check_home_position!(action)
            return if pass_city_ok?(action.entity, action.city)

            raise GameError, "#{token.corporation.name} must choose a home token position that does not need the " \
                             'Right-of-Way green tile (RB 11.1.9)'
          end
        end

        module Operating
          class HomeToken < Engine::Step::HomeToken
            include HomePosition

            def process_place_token(action)
              check_home_position!(action)
              super
            end
          end
        end
      end
    end
  end
end
