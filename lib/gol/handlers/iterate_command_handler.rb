module Gol
  class IterateCommandHandler
    def handle(world_id:)
      p [ :iterate_command_handler ]
      world = World.find(world_id)
      world.iterate!
    end
  end
end
