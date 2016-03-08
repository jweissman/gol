module Gol
  class CreatureDestroyedEvent < Metacosm::Event
    attr_accessor :world_id, :location
  end
end
