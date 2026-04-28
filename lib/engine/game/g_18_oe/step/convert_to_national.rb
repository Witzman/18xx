# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18OE
      module Step
        class ConvertToNational < Engine::Step::Base
          ACTIONS = %w[convert pass].freeze

          def actions(entity)
            player = current_entity
            return [] unless player&.player?

            if entity == player
              # Player can pass once they've had their chance
              return ['pass'] if eligible_majors(player).any?
            elsif entity.corporation? && entity.type == :major && entity.president?(player)
              return ['convert']
            end

            []
          end

          def description
            'Convert Major to National'
          end

          def pass_description
            'Pass (no conversion)'
          end

          def blocks?
            @game.nationals_formation_queue.any?
          end

          def current_entity
            @game.nationals_formation_queue.first
          end

          def active_entities
            queue = @game.nationals_formation_queue
            queue.empty? ? [] : [queue.first]
          end

          def process_convert(action)
            corporation = action.entity
            @game.convert_to_national(corporation)
            # Auto-advance if player has no remaining eligible majors
            player = current_entity
            return unless eligible_majors(player).empty?

            @game.nationals_formation_queue.shift
            pass! if @game.nationals_formation_queue.empty?
          end

          def process_pass(_action)
            # WA-5: use current_entity (queue head), not action.entity which may
            # be routed to the wrong level by the engine's pass handling.
            player = current_entity
            @log << "#{player&.name || '?'} passes national conversion"
            @game.nationals_formation_queue.shift
            pass! if @game.nationals_formation_queue.empty?
          end

          def skip!
            return if @game.nationals_formation_queue.empty?

            # Player has no eligible majors left (all converted) — auto-advance.
            player = current_entity
            @game.nationals_formation_queue.shift
            @log << "#{player.name} has no more majors to convert" if player
            pass! if @game.nationals_formation_queue.empty?
          end

          private

          def eligible_majors(player)
            @game.corporations.select { |c| c.type == :major && c.president?(player) }
          end
        end
      end
    end
  end
end
