require 'metacosm'
require 'parallel'
require 'gosu'
require 'pry'

require 'gol/version'
require 'gol/location'
require 'gol/dimensions'
require 'gol/distance'

require 'gol/creature'
require 'gol/world'

require 'gol/creature_view'
require 'gol/field_view'
require 'gol/world_view'

require 'gol/window'

# TODO move to metacosm
Thread.abort_on_exception=true

module Gol
  class CreateWorldCommand < Metacosm::Command
    attr_accessor :world_id, :dimensions, :generate
  end

  class CreateWorldCommandHandler
    def handle(world_id:, dimensions:)
      World.create(id: world_id, dimensions: dimensions)
    end
  end

  class WorldCreatedEvent < Metacosm::Event
    attr_accessor :world_id, :dimensions
  end

  class WorldCreatedEventListener < Metacosm::EventListener
    def receive(world_id:, dimensions:)
      WorldView.create(world_id: world_id, dimensions: dimensions)
      fire(PopulateWorldCommand.create(world_id: world_id))
    end
  end

  class PopulateWorldCommand < Metacosm::Command
    attr_accessor :world_id
  end

  class PopulateWorldCommandHandler
    def handle(world_id:)
      world = World.find(world_id)
      world.generate_population!
    end
  end

  class WorldPopulatedEvent < Metacosm::Event
    attr_accessor :world_id
  end

  class WorldPopulatedEventListener < Metacosm::EventListener
    def receive(world_id:)
      fire( (IterateCommand.create(world_id: world_id)))
    end
  end

  class CreatureCreatedEvent < Metacosm::Event
    attr_accessor :world_id, :creature_id, :color, :location
  end

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

  class CreatureDestroyedEvent < Metacosm::Event
    attr_accessor :world_id, :location
  end

  class CreatureDestroyedEventListener < Metacosm::EventListener
    def receive(world_id:, location:)
      world_view = WorldView.find_by(world_id: world_id)
      world_view.creature_views.where(location: location).first.destroy
    end
  end

  class IterateCommand < Metacosm::Command
    attr_accessor :world_id
  end

  class IterateCommandHandler
    def handle(world_id:)
      p [ :iterate_command_handler ]
      world = World.find(world_id)
      world.iterate!
    end
  end

  class IterationEvent < Metacosm::Event
    attr_accessor :locations_and_colors, :world_id
  end

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
