# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18OE
      module Step
        class KrasnayaStrelaAssign < Engine::Step::Base
          ACTIONS = %w[assign].freeze

          def actions(entity)
            return [] unless entity.corporation?
            return [] unless entity.id == @game.class::KRASNAYA_STRELA_CORP_ID
            return [] if entity.trains.empty?

            ACTIONS
          end

          def description
            'Assign Krasnaya Strela +1+1 marker'
          end

          def blocks?
            false
          end

          def active_entities
            entity = @game.corporations.find do |c|
              c.id == @game.class::KRASNAYA_STRELA_CORP_ID && c.floated? && !c.closed?
            end
            return [] if entity.nil? || entity.trains.empty?

            [entity]
          end

          def process_assign(action)
            train = action.target
            entity = action.entity
            raise GameError, 'Train not owned by Krasnaya Strela' unless entity.trains.include?(train)

            @game.restore_krasnaya_strela!
            @game.assign_krasnaya_strela!(train)
          end
        end
      end
    end
  end
end
