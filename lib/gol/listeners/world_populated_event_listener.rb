module Gol
  class WorldPopulatedEventListener < Metacosm::EventListener
    def receive(world_id:)
      fire( (IterateCommand.create(world_id: world_id)))
    end
  end
end
