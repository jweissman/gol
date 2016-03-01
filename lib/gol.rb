require 'metacosm'
require 'parallel'
require 'gosu'
# require 'pry'

require 'gol/version'
require 'gol/location'
require 'gol/dimensions'
require 'gol/distance'

require 'gol/creature'

# TODO move to metacosm
Thread.abort_on_exception=true

module Gol
  class Cell < Struct.new(:location, :neighbor_count, :alive)
  end

  class World < Metacosm::Model
    has_many :creatures
    attr_accessor :dimensions

    def generate_population!(n=80)
      puts "---> generate pop! (n=#{n})"
      n.times { print ' '; generate_creature }
      emit(WorldPopulatedEvent.create(world_id: self.id))
      self
    end

    def generate_creature
      # existing_locations = inhabitant_locations
      unique_position = false
      until unique_position
        print '.'
        pos = dimensions.sample
        unique_position = !(Creature.at(pos).any?) #existing_locations.include?(pos))
      end
      print '!'
      create_creature(location: pos)
    end

    def inhabitant_locations
      creatures.map(&:location)
    end

    def restrict_to_dimensions(locs)
      locs.select { |loc| dimensions.contains?(loc) }
    end

    def analyze
      locations          = (inhabitant_locations)
      relevant_locations = restrict_to_dimensions((locations + locations.flat_map(&:neighbors)).uniq)
      p [ :analyze ]
      t0 = Time.now
      relevant_locations.each do |xy|
        neighbor_count = count_neighbors(xy, locations)
        alive          = locations.include?(xy)
        if alive && (neighbor_count < 2 || 3 < neighbor_count)
          doomed = creatures.where.at(xy).first
          doomed.destroy
        elsif (!alive && neighbor_count == 3)
          create_creature(location: xy)
        end
      end
      p [ :analyze_complete, elapsed: (Time.now-t0) ]
    end

    def count_neighbors(xy, locations)
      xy.neighbors.count do |neighbor_loc|
        locations.include?(neighbor_loc)
      end
    end

    def iterate!
      p [ :iterate ]
      analyze

      p [ :rules_applied ]
      emit(
        IterationEvent.create(
          world_id: self.id,
          locations: inhabitant_locations
        )
      )

      p [ :iterate_complete ]
      self
    end
  end

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
      # kickoff iteration...
      fire( (IterateCommand.create(world_id: world_id)))
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
    attr_accessor :locations, :world_id
  end

  class IterationEventListener < Metacosm::EventListener
    def receive(locations:, world_id:)
      # p [ :iteration_event_listener, locations: locations ]
      world_view = WorldView.where(world_id: world_id).first
      world_view.update(locations: locations, history: @history)

      if repeated?(locations)
        p [ :repopulate ]
        @history = []
        fire( PopulateWorldCommand.create(world_id: world_id))
      else
        p [ :reiterate ]
        fire( (IterateCommand.create(world_id: world_id)))
      end
    end

    CYCLE_TO_CHECK = 7
    def repeated?(locations)
      location_set = locations.to_set
      @history ||= []
      @history.push(location_set)
      p [ :repeated?, history_size: @history.size ]

      repeated = (2..CYCLE_TO_CHECK).any? do |i|
        @history.size > i && location_set == @history[-i]
      end

      if @history.size > CYCLE_TO_CHECK
        @history = @history.drop(@history.size - CYCLE_TO_CHECK)
      end

      repeated
    end
  end

  class WorldView < Metacosm::View
    attr_accessor :world_id, :dimensions, :locations, :history

    def render(window)
      return unless locations && locations.any?

      w,h = *dimensions
      cell_width, cell_height = window.width / w, window.height / h

      history&.each_with_index do |historical_view, i|
        historical_view.
          map { |loc| loc.scale(cell_width, cell_height) }.
          each do |location|

            render_cell(location, cell_width, cell_height, window, layer_color(i, history.size))
          end
      end

      scaled_locations = locations.map { |location| location.scale(cell_width, cell_height) }
      scaled_locations.each do |location|
        render_cell(location, cell_width, cell_height, window, base_color)
      end
    end

    def render_cell(location, cell_width, cell_height, window, color)
      x,y = *location
      window.draw_quad(x, y, color,
                       x, y+cell_height, color,
                       x+cell_width, y, color,
                       x+cell_width, y+cell_height, color) # 0xc0c0c0c0)
    end

    protected
    def base_color
      @base_color ||= Gosu::Color.new( 255, 255, 255, 255 )
    end

    def layer_color(layer_index,layer_count)
      opacity = (160 * (layer_index+1)/((layer_count+1).to_f)).to_i
      Gosu::Color.new(opacity, 192, 192, 192)
    end
  end

  class ApplicationWindow < Gosu::Window
    include DimensionHelpers

    attr_accessor :world_id, :width, :height, :history, :sim
    def initialize
      self.width = 640
      self.height = 480

      super(self.width, self.height, true)
      self.caption = 'Hello World!'
      self.world_id = 'gol-instance'
      self.sim = Metacosm::Simulation.current

      self.sim.fire(
        CreateWorldCommand.create(
          world_id: self.world_id,
          dimensions: dim(64,48) #[ 32, 24 ]
        )
      )

      self.sim.conduct!
    end

    def draw
      view.render(self) if view
    end

    protected
    def view
      WorldView.find_by(world_id: self.world_id)
    end
  end
  # end

  if __FILE__ == $0
    window = ApplicationWindow.new
    window.show
  end
end
