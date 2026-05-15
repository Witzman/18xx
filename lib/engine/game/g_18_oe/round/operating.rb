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
          # GoldenBellChoice#process_choose_ability calls start_operating when done.
          super unless @awaiting_golden_bell
        end

        def operating_entities_after_golden_bell
          @game.operating_order.select { |e| @entities.include?(e) }
        end
      end
    end
  end
end
