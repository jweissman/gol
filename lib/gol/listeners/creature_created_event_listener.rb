module Gol
  class CreatureCreatedEventListener < Metacosm::EventListener
    def receive(world_id:, creature_id:, color:, location:)
      world_view = WorldView.find_by(world_id: world_id)
      world_view.create_creature_view(
        creature_id: creature_id,
        world_id: world_id,
        color: color,
        location: location
      )
    end
  end
end
