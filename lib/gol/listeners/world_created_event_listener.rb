module Gol
  class WorldCreatedEventListener < Metacosm::EventListener
    def receive(world_id:, dimensions:)
      WorldView.create(world_id: world_id, dimensions: dimensions)
      fire(PopulateWorldCommand.create(world_id: world_id))
    end
  end
end
