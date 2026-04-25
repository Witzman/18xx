# frozen_string_literal: true

require_relative 'buy_sell_par_shares'
require_relative '../../../step/base'

module Engine
  module Game
    module G18OE
      module Step
        class Consolidate < G18OE::Step::BuySellParShares
        class Consolidate < Engine::Step::Base
          ACTIONS = %w[pass].freeze

          def actions(entity)
            return [] unless entity == current_entity
            return [] if pending_corps(entity).empty?

            can_convert_any? ? ['convert'] : []
          end

          def description
            'Consolidate or abandon minors/regionals'
          end

          def blocks?
            !pending_corps(current_entity).empty?
          end

          def can_convert?(entity)
            return false unless entity.type == :regional
            return false if @converted
            return false unless entity.president?(current_entity)

            true
          end

          def process_convert(action)
            super
          def pass_description
            'Pass (Consolidation TBD)'
          end

          def blocks?
            actions(current_entity).any?
          end

          def process_pass(_action)
            corps = pending_corps(current_entity).map(&:name).join(', ')
            @log << "#{current_entity.name} passes consolidation — pending: #{corps} (merge/abandon TBD)"
            pass!
          end

          private

          def pending_corps(entity)
            @game.corporations.select { |c| c.type == :regional && c.president?(entity) }
            entity.shares.map(&:corporation)
                  .select { |c| %i[minor regional].include?(c.type) }
                  .uniq
          end
        end
      end
    end
  end
end
