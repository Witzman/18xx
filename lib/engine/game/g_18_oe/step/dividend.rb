# frozen_string_literal: true

require_relative '../../../step/dividend'

module Engine
  module Game
    module G18OE
      module Step
        class Dividend < Engine::Step::Dividend
          def dividend_types(entity)
            case
            when entity.minor?
              [:half]
            when entity.respond_to?(:national?) && entity.national?
              [:payout]
            else
              [:payout, :half, :withhold]
            end
          end
        end
      end
    end
  end
end
