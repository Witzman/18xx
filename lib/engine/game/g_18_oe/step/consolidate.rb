# frozen_string_literal: true

require_relative 'buy_sell_par_shares'

module Engine
  module Game
    module G18OE
      module Step
        class Consolidate < G18OE::Step::BuySellParShares
          def actions(entity)
            return [] unless entity == current_entity
            return [] if pending_corps(entity).empty?

            acts = []
            acts << 'convert' if regional_convertible?(entity)
            acts << 'merge'   if can_merge_any?(entity)
            acts
          end

          def description
            'Consolidate or abandon minors/regionals'
          end

          def pass_description
            'Pass'
          end

          def blocks?
            !actions(current_entity).empty?
          end

          def regional_convertible?(entity)
            pending_corps(entity).any? { |corp| can_convert?(corp) }
          end

          def can_convert?(entity)
            return false unless entity.type == :regional
            return false if @converted
            return false unless entity.president?(current_entity)

            true
          end

          def process_convert(action)
            super
            pass!
          end

          # BuySellParShares#process_merge calls pass! ending the player's turn.
          # Consolidation allows multiple merges per turn, so skip auto-pass.
          def process_merge(action)
            minor = action.entity
            major = action.corporation

            raise GameError, "#{minor.name} does not belong to #{current_entity.name}" unless
              minor.president?(current_entity)
            raise GameError, "#{major.name} already received a minor this SR" if
              @round.minors_merged_into.include?(major)

            @game.merge_minor!(minor, major)
            @round.minors_merged_into << major
            track_action(action, major)
          end

          def process_pass(_action)
            pass!
          end

          private

          def pending_corps(entity)
            return [] unless entity

            entity.shares.filter_map(&:corporation)
                  .select { |c| %i[minor regional].include?(c.type) }
                  .uniq
          end
        end
      end
    end
  end
end
