# frozen_string_literal: true

require_relative '../../../round/operating'

module Engine
  module Round
    module G18OE
      class Operating < Engine::Round::Operating
        def select_entities
          # minors and regionals in float order, majors in stock order
          @game.minor_regional_order + (@game.corporations.select(&:floated?) - @game.minor_regional_order).sort
        end

        def after_setup
          @game.golden_bell_position = :normal
          @game.pay_mail_contract!
          super
        end
      end
    end
  end
end
