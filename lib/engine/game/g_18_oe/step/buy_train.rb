# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module G18OE
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          def can_entity_buy_train?(entity)
            entity.corporation?
          end

          def must_buy_train?(entity)
            return false if @game.fulfilled_train_obligation.include?(entity.id)
            return false unless @game.phase.status.include?('train_obligation')

            entity.floated?
          end

          def buyable_trains(entity)
            trains = super

            # Regional/Minor Phase: level 3+ trains blocked for all entities
            return trains.select { |t| t.name == '2+2' } unless @game.major_phase?

            # Obligation window in Major Phase: unfulfilled entity restricted to 2+2
            if @game.phase.status.include?('train_obligation') &&
               !@game.fulfilled_train_obligation.include?(entity.id)
              min = @game.depot.min_depot_train
              return min ? trains.select { |t| t.price == min.price } : []
            end

            trains
          end

          def process_buy_train(action)
            before_phase = @game.phase.name
            in_obligation_window = @game.phase.status.include?('train_obligation')
            super
            after_phase = @game.phase.name
            @game.fulfilled_train_obligation.add(action.entity.id) if in_obligation_window
            return if before_phase == after_phase || !%w[4 6 8].include?(after_phase)

            @game.trigger_nationals_formation!(action.entity.owner)
          end

          # TODO: Nationals claiming rusted trains for free (openpoints §1.9, §3.7) — deferred
        end
      end
    end
  end
end
