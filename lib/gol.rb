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
      # kickoff iteration...
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
    attr_accessor :world_id, :location #:creature_id
  end

  class CreatureDestroyedEventListener < Metacosm::EventListener
    def receive(world_id:, location:)
      world_view = WorldView.find_by(world_id: world_id)
      world_view.creature_views.where(location: location).first.destroy
      # CreatureView.
      #   find_by(world_id: world_id, creature_id: creature_id).
      #   destroy
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
      # world_view = WorldView.where(world_id: world_id).first

      # create a new field view, but we need to copy locations
      # field_view = world_view.field_views.create
      # locations_and_colors.each do |xy, color|
      #   field_view.create_creature_view(location: xy, color: color)
      # end

      # world
      # world_view.update(locations: locations) #, history: @history)

      if repeated?(locations_and_colors)
        @history = []
        fire( PopulateWorldCommand.create(world_id: world_id))
      else
        fire( IterateCommand.create(world_id: world_id))
      end
    end

    CYCLE_TO_CHECK = 7
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

  class CreatureView < Metacosm::View
    belongs_to :world_view
    attr_accessor :world_id, :creature_id, :color, :location

    def render(window, alpha=140)
      return unless location
      color.alpha = alpha

      w,h = *world_view.dimensions
      cell_width = window.width / w
      cell_height = window.height / h
      scaled_location = location.scale(cell_width, cell_height)

      x,y = *scaled_location
      window.draw_quad(x, y, color,
                       x, y+cell_height, color,
                       x+cell_width, y, color,
                       x+cell_width, y+cell_height, color)
    end
  end

  # class FieldView < Metacosm::View
  #   has_many :creature_views
  #   belongs_to :world_view

  #   def dimensions
  #     world_view.dimensions
  #   end

  #   def render(window, alpha)
  #     creature_views.each do |creature_view|
  #       creature_view.render(window, alpha)
  #     end
  #   end
  # end

  class WorldView < Metacosm::View
    attr_accessor :world_id, :dimensions #, :locations, :history
    # has_one :field_view
    # has_many :field_views
    has_many :creature_views #, :through => :most_recentfield_view

    # def top_field
    #   field_views.any? ? field_views.last : field_views.create
    # end

    # def creature_views
    #   top_field.creature_views
    # end

    def render(window)
      # field_views.each_with_index do |field_view, i|
      #   depth = field_views.size - i
      #   field_view.render(window, 240*(depth/field_views.size))
      # end

      # render_trails(window)
      creature_views.each do |creature_view|
        creature_view.render(window)
      end
    end

    # def render_trails(window)
    #   w,h = *dimensions
    #   cell_width, cell_height = window.width / w, window.height / h

    #   history&.each_with_index do |historical_view, i|
    #     historical_view.
    #       map { |loc| loc.scale(cell_width, cell_height) }.
    #       each do |location|

    #         render_cell(location, cell_width, cell_height, window, layer_color(i, history.size))
    #       end
    #   end
    # end

    # def render_cell(location, cell_width, cell_height, window, color)
    #   x,y = *location
    #   window.draw_quad(x, y, color,
    #                    x, y+cell_height, color,
    #                    x+cell_width, y, color,
    #                    x+cell_width, y+cell_height, color)
    # end

    # protected
    # def layer_color(layer_index,layer_count)
    #   opacity = (120 * (layer_index+1)/((layer_count+1).to_f)).to_i
    #   Gosu::Color.new(opacity, 160, 160, 240)
    # end
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
          dimensions: dim(self.width/10,self.height/10)
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
