module Gol
  class Color < Struct.new(:alpha,:red,:green,:blue)
    def +(other_color)
      Gol::Color.new( 255,
                ((self.red+other_color.red)).to_i,
                ((self.green+other_color.green)).to_i,
                ((self.blue+other_color.blue)).to_i)
    end

    def /(scale)
      Gol::Color.new(255,
                (self.red / scale).to_i,
                (self.green / scale).to_i,
                (self.blue / scale).to_i)
    end

    def ==(other_color)
      self.red == other_color.red &&
        self.green == other_color.green &&
        self.blue == other_color.blue
    end

    def to_gosu
      Gosu::Color.new(self.alpha, self.red, self.green, self.blue)
    end

    def self.blue;  @blue  ||= new(255,160,160,240) end
    def self.green; @green ||= new(255,160,240,160) end
    def self.yellow; @yellow ||= new(255,240,240,160) end
  end

  class Creature < Metacosm::Model
    belongs_to :world
    attr_accessor :location, :color
    before_create :assign_color

    def assign_color
      @color ||= [ Gol::Color.blue, Gol::Color.green, Gol::Color.yellow ].sample
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
