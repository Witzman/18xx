# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module G18OE
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          def can_entity_buy_train?(entity)
            return true if entity.player? && entity == current_entity&.owner

            entity.corporation?
          end

          def must_buy_train?(entity)
            return false if @game.fulfilled_train_obligation.include?(entity.id)
            return false unless @game.phase.status.include?('train_obligation')

            entity.floated?
          end

          def can_buy_train?(entity = nil, _shell = nil)
            entity ||= current_entity
            return can_claim_rusted_train?(entity) if entity.type == :national

            super
          end

          # Nationals: only unclaimed rusted trains (free).
          # Others: 2+2 obligation gate + depot level gating.
          def buyable_trains(entity)
            return unclaimed_rusted_trains if entity.type == :national

            trains = super

            return trains.select { |t| t.name == '2+2' } if entity.trains.empty? && @game.phase.name.to_i < 4

            # Level 3+ blocked in the first OR of the game (§11.6)
            return trains.select { |t| t.name == '2+2' } if @game.turn == 1 && @game.round.round_num == 1

            depot_trains = trains.select(&:from_depot?)
            unless depot_trains.empty?
              min_price = depot_trains.map(&:price).min
              trains = trains.reject { |t| t.from_depot? && t.price > min_price }
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

            in_obligation_window = @game.phase.status.include?('train_obligation')
            before_phase = @game.phase.name
            super
            after_phase = @game.phase.name

            @game.fulfilled_train_obligation.add(entity.id) if in_obligation_window

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
