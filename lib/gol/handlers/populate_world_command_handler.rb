module Gol
  class PopulateWorldCommandHandler
    def handle(world_id:)
      world = World.find(world_id)
      world.generate_population!
    end
  end
end
