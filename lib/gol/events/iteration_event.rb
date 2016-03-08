module Gol
  class IterationEvent < Metacosm::Event
    attr_accessor :locations_and_colors, :world_id
  end
end
