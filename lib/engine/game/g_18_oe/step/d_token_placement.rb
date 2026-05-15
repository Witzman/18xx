# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18OE
      module Step
        class DTokenPlacement < Engine::Step::Base
          ACTIONS = %w[assign].freeze

          def actions(entity)
            return [] unless entity.corporation?
            return [] unless entity.id == @game.class::D_TOKEN_CORP_ID
            return [] unless @game.d_token_available?(entity)

            ACTIONS
          end

          def description
            'Place Green Junction marker'
          end

          def blocks?
            false
          end

          def process_assign(action)
            hex = action.target
            raise GameError, 'Invalid hex for Green Junction marker' unless @game.valid_d_token_hex?(hex)

            @game.assign_d_token!(hex)
          end

          def available_hex(entity, hex)
            return unless @game.d_token_available?(entity)
            return unless @game.valid_d_token_hex?(hex)

            [0]
          end
        end
      end
    end
  end
end
