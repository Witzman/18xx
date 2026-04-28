# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module G18OE
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          def must_buy_train?(entity)
            entity.floated? && entity.trains.empty? && (!@game.fulfilled_train_obligation?(entity) || entity.type == :major)
          end

          def can_buy_train?(entity = nil, _shell = nil)
            entity ||= current_entity
            return can_claim_rusted_train?(entity) if entity.type == :national

            super
          end

          def buyable_trains(entity)
            return unclaimed_rusted_trains if entity.type == :national

            trains = super

            # Regional/Minor Phase: level 3+ trains blocked for all entities
            return trains.select { |t| t.name == '2+2' } unless @game.major_phase?

            # Obligation window in Major Phase: unfulfilled entity restricted to 2+2
            if @game.phase.status.include?('train_obligation') &&
               !@game.fulfilled_train_obligation?(entity)
              min = @game.depot.min_depot_train
              return min ? trains.select { |t| t.price == min.price } : []
            end

            trains
          end

          def spend_minmax(entity, train)
            return [0, 0] if entity.type == :national && train.rusted

            super
          end

          def process_buy_train(action)
            entity = action.entity
            train  = action.train

            if entity.type == :national && train.rusted
              entity.trains << train
              train.owner = entity
              @game.log << "#{entity.name} claims rusted #{train.name} train for free"
              pass! unless can_claim_rusted_train?(entity)
              return
            end

            before_phase = @game.phase.name
            super
            after_phase = @game.phase.name
            @game.fulfill_train_obligation!(entity) if train.name == '2+2' && train.from_depot?
            return if before_phase == after_phase || !%w[4 6 8].include?(after_phase)

            @game.trigger_nationals_formation!(entity.owner)
          end

          private

          def unclaimed_rusted_trains
            @game.depot.trains.select { |t| t.rusted && t.owner.nil? }
          end

          def can_claim_rusted_train?(entity)
            unclaimed_rusted_trains.any? &&
              @game.num_corp_trains(entity) < @game.train_limit(entity)
          end
        end
      end
    end
  end
end
