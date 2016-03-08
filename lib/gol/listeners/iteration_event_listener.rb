module Gol
  class IterationEventListener < Metacosm::EventListener
    def receive(locations_and_colors:, world_id:)
      if repeated?(locations_and_colors)
        @history = []
        fire( PopulateWorldCommand.create(world_id: world_id))
      else
        fire( IterateCommand.create(world_id: world_id))
      end
    end

    CYCLE_TO_CHECK = 15
    def repeated?(locations)
      location_set = locations.to_set
      @history ||= []
      @history.push(location_set)

      repeated = (2..CYCLE_TO_CHECK).any? do |i|
        @history.size > i && location_set == @history[-i]
      end

      if @history.size > CYCLE_TO_CHECK
        @history = @history.drop(@history.size - CYCLE_TO_CHECK)
      end

      repeated
    end
  end
end
