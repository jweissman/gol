module Gol
  class Creature < Metacosm::Model
    belongs_to :world
    attr_accessor :location, :color
    before_create :assign_color

    def assign_color
      @color ||= palette.sample
    end

    def palette
      [ Gol::Color.blue, Gol::Color.green, Gol::Color.yellow ]
    end

    def self.survives?(surrounding_count)
      !(surrounding_count < 2 || 3 < surrounding_count)
    end

    def self.born?(surrounding_count)
      surrounding_count == 3
    end

    def self.next_state(alive, surrounding_count)
      return Creature.survives?(surrounding_count) if alive
      Creature.born?(surrounding_count)
    end

    def self.next_color(xy)
      neighbors_of(xy).average(:color)
    end

    ## scopes
    def self.at(loc)
      where(location: loc)
    end

    def self.neighbors_of(xy)
      where(location: xy.neighbors)
    end
  end
end
