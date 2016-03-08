module Gol
  class CreatureDestroyedEventListener < Metacosm::EventListener
    def receive(world_id:, location:)
      world_view = WorldView.find_by(world_id: world_id)
      world_view.creature_views.where(location: location).first.destroy
    end
  end
end
