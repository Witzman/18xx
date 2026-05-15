# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18OE
      module Step
        class GoldenBellChoice < Engine::Step::Base
          ACTIONS = %w[choose_ability].freeze

          def round_state
            { awaiting_golden_bell: false }
          end

          def setup
            @round.awaiting_golden_bell = !@game.golden_bell_entity.nil?
          end

          def actions(entity)
            return [] unless @round.awaiting_golden_bell
            return [] unless entity == @game.golden_bell_entity

            ACTIONS
          end

          def active?
            @round.awaiting_golden_bell
          end

          def blocking?
            @round.awaiting_golden_bell
          end

          def active_entities
            return [] unless @round.awaiting_golden_bell

            [@game.golden_bell_entity].compact
          end

          def description
            'Golden Bell Operating Order'
          end

          def choice_name
            'Choose operating position this OR'
          end

          def choices
            { 'first' => 'First', 'last' => 'Last', 'normal' => 'Normal order' }
          end

          def process_choose_ability(action)
            entity = action.entity
            raise GameError, 'Not the Golden Bell entity' unless entity == @game.golden_bell_entity

            ability = @game.abilities(entity, :choose_ability)
            choice = action.choice.to_sym
            @game.golden_bell_position = choice
            @round.awaiting_golden_bell = false
            @game.log << "#{entity.name} will operate #{choice} this OR"
            ability&.use!
            @round.entities.replace(@round.operating_entities_after_golden_bell)
            @round.start_operating
          end

          def skip!
            pass!
          end
        end
      end
    end
  end
end
