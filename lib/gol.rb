require 'metacosm'
require 'gol/version'
include Metacosm

class Location < Struct.new(:x,:y)
  def inspect; "(#{x},#{y})" end
end
def coord(x,y); Location.new(x,y) end

module ActsAsNavigable
  def dimensions
    raise "Override #dimensions in #{self.class.name} (ActsAsNavigable)"
  end

  def each_location
    h,w = *dimensions
    (0...h).each do |y|
      (0...w).each do |x|
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

  # use like `Inhabitant.neighbors_of(coord(0,0))`
  def self.neighbors_of(location)
    Inhabitant.
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
  before_create :ensure_dimensions_set, :generate_population

  def ensure_dimensions_set
    @dimensions ||= [10,10]
  end

  def generate_population
    self
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
    field = assemble_field
    field.each(&method(:apply_rules))

    emit(
      IterationEvent.create(
        world_id: self.id, 
        locations: inhabitant_locations
      )
    )

    self
  end

  def apply_rules(location:,neighbor_count:,alive:)
    if alive
      if neighbor_count < 2 || 3 < neighbor_count
        kill_inhabitant_at(location) 
      end
    else # !alive
      if neighbor_count == 3
        birth_inhabitant_at(location) 
      end
    end
  end

  def kill_inhabitant_at(location)
    doomed = inhabitants.where.at(location).first
    doomed.destroy
  end

  def birth_inhabitant_at(location)
    create_inhabitant(location: location)
  end

  def minimum_neighbors
    3
  end

  def maximum_neighbors
    6
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
    world_view = WorldView.where(world_id: world_id).first_or_create
    world_view.update(locations: locations)
  end
end

class WorldView < View
  attr_accessor :world_id, :dimensions, :locations
end
