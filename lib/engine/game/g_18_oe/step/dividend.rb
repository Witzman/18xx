# frozen_string_literal: true

require_relative '../../../step/dividend'

module Engine
  module Game
    module G18OE
      module Step
        class Dividend < Engine::Step::Dividend
          # WA-2 (permanent): inject national revenue here via current_entity rather
          # than via game.routes_revenue which relies on current_operator being set.
          def total_revenue
            return @game.national_revenue(current_entity) if current_entity&.type == :national

            super
          end

          def dividend_types(entity)
            if entity.minor?
              [:half]
            elsif entity.respond_to?(:national?) && entity.national?
              [:payout]
            else
              %i[payout half withhold]
            end
          end
        end
      end
    end
  end
end
