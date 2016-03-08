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


    def self.red;    @red    ||= new(255,high,low,low) end
    def self.blue;   @blue   ||= new(255,low,low,high) end
    def self.green;  @green  ||= new(255,low,high,low) end
    def self.yellow; @yellow ||= new(255,high,high,low) end

    def self.high; 240 end
    def self.low;  160 end
  end
end
