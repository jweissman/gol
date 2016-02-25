require 'metacosm'
require 'gol/version'
include Metacosm

class Inhabitant < Model
  belongs_to :world
  attr_accessor :location

  def cohort
    world.inhabitants.all - [self]
  end

  def neighbors
    cohort.select do |potential_neighbor|
      distance_to(potential_neighbor.location) <= 1.0
    end
  end

  def distance_to(other_location)
    x0,y0 = *location
    x1,y1 = *other_location
    dx = ((x0 - x1) ** 2)
    dy = ((y0 - y1) ** 2)
    Math.sqrt( dx + dy )
  end
end

class World < Model
  has_many :inhabitants
  attr_accessor :dimensions
  before_create :ensure_dimensions_set, :generate_population

  def ensure_dimensions_set
    @dimensions ||= [10,10]
  end

  def generate_population
    # self.inhabitants << Inhabitant.create(location: [0,0])
  end

  def inhabitant_locations
    inhabitants.map(&:location)
  end

  def iterate!
    emit(IterationEvent.create(world_id: self.id, locations: inhabitant_locations))
    self
    # ....
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
    view = WorldView.find_by(world_id: world_id)
    view.clear_field!
    locations.each do |location|
      x,y = *location
      view.field[y][x] = true
    end
  end
end

class WorldView < View
  attr_accessor :world_id, :field, :dimensions

  def clear_field!
    field ||= []
    w,h = *dimensions
    (1..h).each do |y|
      field[y] ||= []
      (1..w).each do |x|
        field[y][x] = false
      end
    end
  end
end
