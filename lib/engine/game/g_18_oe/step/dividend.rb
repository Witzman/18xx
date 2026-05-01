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
            if entity&.type == :minor
              [:half]
            elsif entity&.type == :national
              [:payout]
            else
              %i[withhold half payout]
            end
          end
        end
      end
    end
  end
end
