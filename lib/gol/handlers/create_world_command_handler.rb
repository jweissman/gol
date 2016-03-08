module Gol
  class CreateWorldCommandHandler
    def handle(world_id:, dimensions:)
      World.create(id: world_id, dimensions: dimensions)
    end
  end
end
