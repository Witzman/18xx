# frozen_string_literal: true

require_relative '../../../step/token'

module Engine
  module Game
    module G18OE
      module Step
        class Token < Engine::Step::Token
          def available_hex(entity, hex)
            return nil unless @game.hex_within_national_region?(entity, hex)

            super
          end

          def check_connected(entity, city, hex)
            city_string = hex.tile.cities.size > 1 ? " city #{city.index}" : ''
            unless @game.hex_within_national_region?(entity, hex)
              raise GameError, "Cannot place token on #{hex.name} because it is outside #{entity.name}'s track rights zone"
            end

            return if @game.loading || @game.token_graph_for_entity(entity).connected_nodes(entity)[city]

            raise GameError, "Cannot place token on #{hex.name}#{city_string} because it is not connected"
          end

          def place_token(entity, city, token, connected: true, extra_action: false,
                          special_ability: nil, check_tokenable: true, spender: nil, same_hex_allowed: false)
            super
            return unless special_ability&.type == :token
            return unless special_ability.owner.is_a?(Engine::Company)
            return unless special_ability.owner.sym == @game.class::CCTC_COMPANY_SYM

            @game.setup_cctc_revenue!(entity, city.hex)
          end
        end
      end
    end
  end
end
