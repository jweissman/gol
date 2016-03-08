module Gol
  class CreatureCreatedEvent < Metacosm::Event
    attr_accessor :world_id, :creature_id, :color, :location
  end
end
