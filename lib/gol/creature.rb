module Gol
  class Creature < Metacosm::Model
    belongs_to :world
    attr_accessor :location

    def self.at(loc)
      where(location: loc)
    end

    def self.neighbors_of(other_location)
      where(location: other_location.neighbors).all
    end
  end
end
