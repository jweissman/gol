module Gol
  class Location < Struct.new(:x,:y)
    def inspect
      "(#{x},#{y})"
    end

    def neighbors
      [translate(-1,0),
       translate(1,0),
       translate(0,-1),
       translate(0,1),
       translate(-1,-1),
       translate(1,-1),
       translate(1,1),
       translate(-1,1)]
    end

    def neighbors_of_neighbors
      neighbors.flat_map(&:neighbors).uniq
    end

    def extended_neighbors
      neighbors_of_neighbors.flat_map(&:neighbors_of_neighbors).uniq
    end

    def scale(sx,sy)
      Location.new(sx*x,sy*y)
    end

    def translate(dx,dy)
      Location.new(x+dx, y+dy)
    end
  end

  module LocationHelpers
    def coord(x,y); Location.new(x,y) end
  end
end
