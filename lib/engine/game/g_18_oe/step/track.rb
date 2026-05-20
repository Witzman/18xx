# frozen_string_literal: true

require_relative '../../../step/track'

module Engine
  module Game
    module G18OE
      module Step
        class Track < Engine::Step::Track
          def setup
            super
            @points_used = 0
          end

          def can_lay_tile?(entity)
            points_available = get_tile_lay(entity) - @points_used
            return false unless points_available.positive?

            !entity.tokens.empty?
          end

          def get_tile_lay(entity)
            @game.tile_point_budget(entity) + (@game.class::EXTRA_TILE_POINTS[entity.id] || 0)
          end

          def description
            tile_lay = get_tile_lay(current_entity) - @points_used
            "#{tile_lay} track points"
          end

          def lay_tile_action(action)
            entity  = action.entity
            hex     = action.hex
            tile    = action.tile
            old_tile = hex.tile
            metropolis = @game.metropolis_tile?(tile)
            points_available = get_tile_lay(entity) - @points_used
            points_cost = if metropolis
                            tile.color == :yellow ? 2 : 4
                          elsif tile.color != :yellow
                            (@game.discounted_upgrade?(entity) && tile.cities.empty?) ? 1 : 2
                          else
                            1
                          end
            raise GameError, 'Cannot lay an upgrade now' if tile.color != :yellow && points_cost > points_available
            raise GameError, 'Cannot lay a yellow now' if tile.color == :yellow && points_cost > points_available

            bbe_used = @game.bbe_active_for_lay?(entity, hex)

            lay_tile(action)
            @game.log << "Used #{points_cost} tile point(s) to lay tile"
            @game.log << "#{points_available - points_cost} point(s) remaining"
            if track_upgrade?(old_tile, tile, hex)
              @round.upgraded_track = true
              @round.num_upgraded_track += 1
            end
            @round.num_laid_track += 1
            @round.laid_hexes << hex
            @points_used += points_cost

            return unless bbe_used

            bbe = @game.company_by_id(@game.class::BBE_COMPANY_SYM)
            ability = @game.abilities(bbe, :tile_lay)
            ability&.use!
            @game.mark_bbe_hex!(hex, entity)
            return unless ability&.count&.zero?

            @game.company_closing_after_using_ability(bbe)
            bbe.close!
          end

          def tracker_available_hex(entity, hex)
            return nil unless @game.hex_within_national_region?(entity, hex)

            connected = hex_neighbors(entity, hex)
            return nil unless connected

            points_available = get_tile_lay(entity) - @points_used
            return nil unless points_available

            metropolis = @game.metropolis_hex?(hex)
            color = hex.tile.color
            min_upgrade_cost = @game.discounted_upgrade?(entity) ? 1 : 2
            return nil if color == :blue
            return nil if color == :white && metropolis && points_available < 2
            return nil if color == :white && points_available < 1
            return nil if color != :white && metropolis && points_available < 4
            return nil if color != :white && points_available < min_upgrade_cost

            connected
          end
        end
      end
    end
  end
end
