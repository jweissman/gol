module Gol
  class Dimensions < Struct.new(:width,:height)
    include LocationHelpers

    def inspect
      "#{width}x#{height}"
    end

    def contains?(position)
      x_range.include?(position[0]) && y_range.include?(position[1])
    end

    def sample
      x,y = x_range.to_a.sample, y_range.to_a.sample
      coord(x,y)
    end

    def area
      x_range.size * y_range.size
    end

    def x_range
      1...(width-1)
    end

    def y_range
      1...(height-1)
    end

    def all_locations
      @all_locations ||= assemble_all_locations
    end

    def assemble_all_locations
      locs = []
      x_range.each do |x|
        y_range.each do |y|
          locs.push coord(x,y)
        end
      end
      locs
    end
  end

  module DimensionHelpers
    def dim(w,h); Dimensions.new(w,h) end
  end
end
