# frozen_string_literal: true

require_relative '../../../step/dividend'
require_relative '../../../step/half_pay'

module Engine
  module Game
    module G18OE
      module Step
        class Dividend < Engine::Step::Dividend
          include Engine::Step::HalfPay

          # WA-2 (permanent): inject national revenue here via current_entity rather
          # than via game.routes_revenue which relies on current_operator being set.
          def total_revenue
            return @game.national_revenue(current_entity) if current_entity&.type == :national

            super
          end

          def dividend_types(entity = current_entity)
            case entity&.type
            when :minor
              [:half]
            when :national
              [:payout]
            else
              %i[withhold half payout]
            end
          end

          # Base skip! always uses 'withhold', which isn't in dividend_types for minors/nationals.
          # Use the entity's first valid type so dividend_options lookup doesn't return nil.
          def skip!
            kind = dividend_types(current_entity).first.to_s
            action = Action::Dividend.new(current_entity, kind: kind)
            action.id = @game.actions.last.id if @game.actions.last
            process_dividend(action)
          end
        end
      end
    end
  end
end
