module Gol
  class World < Metacosm::Model
    has_many :creatures
    attr_accessor :dimensions

    def generate_population!(n=(dimensions.area * 0.05).to_i)
      puts "---> generate pop! (n=#{n})"
      locs = restrict_to_dimensions(dimensions.all_locations - inhabitant_locations).sample(n)
      n.times { create_creature(location: locs.shift) }
      emit(WorldPopulatedEvent.create(world_id: self.id))
      self
    end

    def iterate!
      analyze
      emit(iteration_event)
      self
    end

    protected

    def iteration_event
      IterationEvent.create(world_id: id, locations_and_colors: inhabitant_locations_and_colors)
    end

    def inhabitant_locations_and_colors
      creatures.map { |creature| [ creature.location, creature.color ] }.to_h
    end

    def random_uninhabited_location
      (dimensions.all_locations - inhabitant_locations).sample
    end

    def inhabitant_locations
      creatures.map(&:location)
    end

    def restrict_to_dimensions(locs)
      locs.select { |loc| dimensions.contains?(loc) }
    end

    def analyze
      locations          = inhabitant_locations
      relevant_locations = restrict_to_dimensions((locations + locations.flat_map(&:neighbors)).uniq)
      p [ :analyze ]

      t0 = Time.now
      actions = []

      relevant_locations.each do |xy|
        neighbor_count = count_neighbors(xy, locations)
        alive          = Creature.at(xy).any?
        alive_next_step = Creature.next_state(alive, neighbor_count)
        if    alive && !alive_next_step
          actions.push({ cmd: 'destroy', xy: xy })
        elsif !alive && alive_next_step
          actions.push({ cmd: 'create', xy: xy, color: majority_neighbor_color(xy) })
        end
      end

      actions.each do |action|
        xy = action[:xy]
        case action[:cmd]
        when 'destroy' then creatures.where.at(xy).first.destroy
        when 'create' then create_creature(location: xy, color: action[:color])
        end
      end

      p [ :analyze_complete, elapsed: (Time.now-t0) ]
    end

    def count_neighbors(xy, locations)
      xy.neighbors.count do |neighbor_loc|
        locations.include?(neighbor_loc)
      end
    end

    def majority_neighbor_color(xy)
      Creature.
        neighbors_of(xy).
        mode(:color)
    end
  end
end
