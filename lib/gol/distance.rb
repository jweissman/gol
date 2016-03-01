module Gol
  module Distance
    def self.between(a,b)
      x0,y0 = *a
      x1,y1 = *b
      dx = ((x0 - x1) ** 2)
      dy = ((y0 - y1) ** 2)
      Math.sqrt( dx + dy )
    end
  end
end
