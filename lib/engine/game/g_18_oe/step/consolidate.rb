# frozen_string_literal: true

require_relative 'buy_sell_par_shares'

module Engine
  module Game
    module G18OE
      module Step
        class Consolidate < G18OE::Step::BuySellParShares
          CONVERT_ACTIONS = ['convert'].freeze

          def actions(entity)
            return [] unless entity == current_entity
            return [] if pending_corps(entity).empty?

            regional_convertible?(entity) ? CONVERT_ACTIONS : []
          end

          def description
            'Consolidate or abandon minors/regionals'
          end

          def pass_description
            'Pass (Consolidation TBD)'
          end

          def blocks?
            actions(current_entity).any?
          end

          def regional_convertible?(entity)
            pending_corps(entity).any? { |corp| can_convert?(corp) }
          end

          def can_convert?(entity)
            entity.type == :regional && !@converted
          end

          def process_convert(action)
            super
            pass!
          end

          def process_pass(_action)
            corps = pending_corps(current_entity).map(&:name).join(', ')
            @log << "#{current_entity.name} passes consolidation — pending: #{corps} (merge/abandon TBD)"
            pass!
          end

          private

          def pending_corps(entity)
            entity.shares.map(&:corporation)
                  .select { |c| %i[minor regional].include?(c.type) }
                  .uniq
          end
        end
      end
    end
  end
end
