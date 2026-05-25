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
            acts << 'choose'  if can_abandon_any?(entity)
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

          def choice_available?(_entity)
            true
          end

          def choice_name
            'Abandon minor'
          end

          def choices
            abandonable_minors(current_entity).to_h { |c| [c.id, c.name] }
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

          def can_abandon_any?(entity)
            !abandonable_minors(entity).empty?
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

          def process_choose(action)
            minor = @game.corporation_by_id(action.choice)
            raise GameError, "#{action.choice} is not an abandonable minor" unless
              abandonable_minors(current_entity).include?(minor)

            @game.abandon_minor!(minor)
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

          def abandonable_minors(entity)
            return [] if eligible_merge_targets.any?

            pending_corps(entity).select { |c| c.type == :minor }
          end
        end
      end
    end
  end
end
