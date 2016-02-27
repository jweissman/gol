require 'metacosm'
require 'pry'
require 'gosu'

require 'gol/version'

include Metacosm

class Location < Struct.new(:x,:y)
  def inspect; "(#{x},#{y})" end
  def scale(sx,sy); Location.new(sx*x,sy*y) end
end
def coord(x,y); Location.new(x,y) end

module ActsAsNavigable
  def dimensions
    raise "Override #dimensions in #{self.class.name} (ActsAsNavigable)"
  end

  def each_location
    h,w = *dimensions
    (0..h).each do |y|
      (0..w).each do |x|
        yield Location.new(x,y)
      end
    end
  end
end

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

  def to_cell
    {
      location: location,
      alive: Inhabitant.at(location).any?,
      neighbor_count: Inhabitant.neighbors_of(location).count
    }
  end

  # use like `Inhabitant.neighbors_of(coord(0,0))`
  def self.neighbors_of(location)
    where.not.at(location).
    select do |potential_neighbor|
      within_unit_distance(location, potential_neighbor.location)
    end
  end

  def self.within_unit_distance(a,b)
    # right triangles of unit width and height have
    # a hypotenuse of root 2
    Distance.between(a,b) <= Math.sqrt(2)
  end
end

class World < Model
  include ActsAsNavigable

  has_many :inhabitants
  attr_accessor :dimensions
  after_create :generate_population

  def generate_population
    300.times { print '.'; generate_inhabitant }
    self
  end

  def generate_inhabitant
    w,h=*dimensions

    pos = coord( (0..w).to_a.sample, (0..h).to_a.sample )
    create_inhabitant(location: pos)
  end

  def inhabitant_locations
    inhabitants.map(&:location)
  end

  def assemble_field
    field = []
    each_location do |xy|
      field.push location: xy,
        neighbor_count: Inhabitant.neighbors_of(xy).count,
        alive: Inhabitant.where.at(xy).any?
    end
    field
  end

  def iterate!
    field_cells = assemble_field
    field_cells.each(&method(:apply_rules))

    emit(
      IterationEvent.create(
        world_id: self.id,
        locations: inhabitant_locations
      )
    )

    self
  end

  def apply_rules(location:,neighbor_count:,alive:)
    puts "---> applying rules at #{location}"
    if alive
      if neighbor_count < 2 || 3 < neighbor_count
        doomed = inhabitants.where.at(location).first
        doomed.destroy
      end
    else # !alive
      if neighbor_count == 3
        create_inhabitant(location: location)
      end
    end
  end
end

class CreateWorldCommand < Command
  attr_accessor :world_id, :dimensions
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
  end
end

class IterateCommand < Command
  attr_accessor :world_id
end

class IterateCommandHandler
  def handle(world_id:)
    world = World.find(world_id)
    world.iterate!
  end
end

class IterationEvent < Event
  attr_accessor :locations, :world_id
end

class IterationEventListener < EventListener
  def receive(locations:, world_id:)
    p [ :iteration_event_listener, locations: locations ]
    world_view = WorldView.where(world_id: world_id).first
    world_view.update(locations: locations)
  end
end

class WorldView < View
  attr_accessor :world_id, :dimensions, :locations

  def render(window)
    w,h = *dimensions
    cell_width, cell_height = window.width / h, window.height / w

    if locations.any?
      scaled_locations = locations.map { |location| location.scale(cell_width, cell_height) }
      scaled_locations.each do |location|
        render_cell(location, cell_width, cell_height, window)
      end
    end
  end

  def render_cell(location, cell_width, cell_height, window, color=0xffffffff)
    x,y = *location
    window.draw_quad(x, y, color,
                     x, y+cell_height, color,
                     x+cell_width, y, color,
                     x+cell_width, y+cell_height, color)
  end
end

class ApplicationWindow < Gosu::Window
  attr_accessor :world_id, :width, :height
  def initialize
    self.width = 640
    self.height = 480

    super(self.width, self.height)
    self.caption = 'Hello World!'
    self.world_id = 'gol-instance'

    Simulation.current.apply(
      CreateWorldCommand.create(world_id: self.world_id, dimensions: [ 32, 24 ])
    )
  end

  def update
    Simulation.current.apply(
      (IterateCommand.create(world_id: self.world_id))
    )
  end

  def draw
    view = WorldView.find_by(world_id: self.world_id)
    view.render(self)
  end
end

if __FILE__ == $0
  window = ApplicationWindow.new
  window.show
end
