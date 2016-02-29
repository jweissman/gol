require 'metacosm'
require 'parallel'
require 'gosu'
require 'pry'

require 'gol/version'

include Metacosm

class Location < Struct.new(:x,:y)
  def inspect
    "(#{x},#{y})"
  end

  def neighbors
    [translate(-1,0),
     translate(1,0),
     translate(0,-1),
     translate(0,1),
     translate(-1,-1),
     translate(1,-1),
     translate(1,1),
     translate(-1,1)]
  end

  def scale(sx,sy)
    Location.new(sx*x,sy*y)
  end

  def translate(dx,dy)
    Location.new(x+dx, y+dy)
  end

  def within?((w,h))
    0 <= x && x <= w && 0 <= y && y <= h
  end
end
def coord(x,y); Location.new(x,y) end

module Distance
  def self.between(a,b)
    x0,y0 = *a
    x1,y1 = *b
    dx = ((x0 - x1) ** 2)
    dy = ((y0 - y1) ** 2)
    Math.sqrt( dx + dy )
  end
end

class Inhabitant < Model
  belongs_to :world
  attr_accessor :location

  def self.at(loc)
    where(location: loc)
  end

  def self.neighbors_of(other_location)
    where(location: other_location.neighbors).all
  end
end

class Cell < Struct.new(:location, :neighbor_count, :alive)
end

class World < Model
  has_many :inhabitants
  attr_accessor :dimensions

  def generate_population!(n=150)
    puts "---> generate pop! (n=#{n})"
    n.times { print '.'; generate_inhabitant }
    emit(WorldPopulatedEvent.create(world_id: self.id))
    self
  end

  def generate_inhabitant
    w,h=*dimensions
    existing_locations = inhabitant_locations
    unique_position = false
    until unique_position
      pos = coord( (0..h).to_a.sample, (0..w).to_a.sample )
      unique_position = !(existing_locations.include?(pos))
    end
    create_inhabitant(location: pos)
  end

  def inhabitant_locations
    inhabitants.map(&:location)
  end

  def restrict_to_dimensions(locs)
    locs.select { |loc| loc.within?([dimensions[1], dimensions[0]]) }
  end

  def analyze
    locations = inhabitant_locations
    relevant_locations = restrict_to_dimensions((locations + locations.flat_map(&:neighbors)).uniq)
    p [ :analyze ]
    t0 = Time.now
    relevant_locations.each do |xy|
      neighbor_count = count_neighbors(xy, locations)
      alive          = locations.include?(xy)
      if alive && (neighbor_count < 2 || 3 < neighbor_count)
        doomed = inhabitants.where.at(xy).first
        doomed.destroy
      elsif (!alive && neighbor_count == 3)
        create_inhabitant(location: xy)
      end
    end
    p [ :analyze_complete, elapsed: (Time.now-t0) ]
  end

  def count_neighbors(xy, locations)
    xy.neighbors.count do |neighbor_loc|
      locations.include?(neighbor_loc)
    end
  end

  def each_location
    h,w = *dimensions
    (0..h).each do |y|
      (0..w).each do |x|
        yield Location.new(x,y)
      end
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

class CreateWorldCommand < Command
  attr_accessor :world_id, :dimensions, :generate
end

class CreateWorldCommandHandler
  def handle(world_id:, dimensions:)
    World.create(id: world_id, dimensions: dimensions)
  end
end

class WorldCreatedEvent < Event
  attr_accessor :world_id, :dimensions
end

class WorldCreatedEventListener < EventListener
  def receive(world_id:, dimensions:)
    WorldView.create(world_id: world_id, dimensions: dimensions)
    fire(PopulateWorldCommand.create(world_id: world_id))
  end
end

class PopulateWorldCommand < Command
  attr_accessor :world_id
end

class PopulateWorldCommandHandler
  def handle(world_id:)
    world = World.find(world_id)
    world.generate_population!
  end
end

class WorldPopulatedEvent < Event
  attr_accessor :world_id
end

class WorldPopulatedEventListener < EventListener
  def receive(world_id:)
    # kickoff iteration...
    fire( (IterateCommand.create(world_id: world_id)))
  end
end

class IterateCommand < Command
  attr_accessor :world_id
end

class IterateCommandHandler
  def handle(world_id:)
    p [ :iterate_command_handler ]
    world = World.find(world_id)
    world.iterate!
  end
end

class IterationEvent < Event
  attr_accessor :locations, :world_id
end

class IterationEventListener < EventListener
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

  CYCLE_TO_CHECK = 20
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

class WorldView < View
  attr_accessor :world_id, :dimensions, :locations, :history

  def render(window)
    return unless locations && locations.any?

    w,h = *dimensions
    cell_width, cell_height = window.width / h, window.height / w

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
                     x+cell_width, y+cell_height, color)
  end

  protected
  def base_color
    @base_color ||= Gosu::Color.new( 255, 192, 192, 192 )
  end

  def layer_color(layer_index,layer_count)
    Gosu::Color.new((192 * (layer_index+1)/((layer_count+1).to_f)).to_i, 192, 192, 192)
  end
end

class ApplicationWindow < Gosu::Window
  attr_accessor :world_id, :width, :height, :history, :sim
  def initialize
    self.width = 640
    self.height = 480

    super(self.width, self.height, true)
    self.caption = 'Hello World!'
    self.world_id = 'gol-instance'
    self.sim = Simulation.current

    self.sim.apply(
      CreateWorldCommand.create(
        world_id: self.world_id,
        dimensions: [ 24, 32 ]
      )
    )

    self.sim.conduct!
  end

  def update
    # all handled async now...
  end

  def draw
    view.render(self) if view
  end

  protected
  def view
    WorldView.find_by(world_id: self.world_id)
  end
end

if __FILE__ == $0
  window = ApplicationWindow.new
  window.show
end
