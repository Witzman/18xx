# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18OE
      module Step
        class HochbergPlacement < Engine::Step::Base
          ACTIONS = %w[assign].freeze

          def actions(entity)
            return [] unless entity.company?
            return [] unless entity.sym == @game.class::HMLC_COMPANY_SYM
            return [] unless @game.abilities(entity, :assign_hexes)

            ACTIONS
          end

          def description
            'Place Hochberg Mining token'
          end

          def blocks?
            false
          end

          def process_assign(action)
            company = action.entity
            hex = action.target
            ability = @game.abilities(company, :assign_hexes)
            raise GameError, 'Hex not eligible for Hochberg token' unless @game.hochberg_eligible_hex?(hex)

            ability.hexes.replace([hex.coordinates])
            hex.assign!(company.id)
            company.close!
            @game.log << "#{company.name} token placed on #{hex.name}; only owner's RRs may use this track"
            ability.use!
          end

          def available_hex(entity, hex)
            return unless entity.sym == @game.class::HMLC_COMPANY_SYM
            return unless @game.hochberg_eligible_hex?(hex)

            [0]
          end
        end
      end
    end
  end
end
