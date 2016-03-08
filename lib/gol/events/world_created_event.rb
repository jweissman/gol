module Gol
  class WorldCreatedEvent < Metacosm::Event
    attr_accessor :world_id, :dimensions
  end
end
