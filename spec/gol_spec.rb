require 'spec_helper'
require 'pry'
require 'gol'

describe World do
  include Gol::LocationHelpers
  include Gol::DimensionHelpers
  let(:world) { World.create(dimensions: dimensions) }
  let(:dimensions) { dim(10,10) }
  before { world.create_creature(location: coord(2,3)) }

  it 'should build a 2-d field' do
    expect(world.creatures.all).to eq([Creature.first])
  end
end

describe Creature do
  include Gol::LocationHelpers
  include Gol::DimensionHelpers

  before(:each) { PassiveRecord.drop_all }
  let(:world) { World.create(dimensions: dimensions) }
  let(:pos) { coord(0,0) }
  let(:dimensions) { dim(10,10) }
  subject(:creature) { world.create_creature(location: pos) }

  describe 'instance attributes' do
    it 'should have a location' do
      expect(creature.location).to eq(pos)
    end
  end

  describe 'class methods' do
    it 'should have an .at scope' do
      expect(creature).to eq(Creature.at(coord(0,0)).first)
    end
  end

  context 'counting neighbors' do
    let!(:a) { Creature.create(location: coord(0,0), world: world) }
    let!(:b) { Creature.create(location: coord(0,1), world: world) }
    let!(:c) { Creature.create(location: coord(0,2), world: world) }
    let!(:d) { Creature.create(location: coord(3,3), world: world) }

    it 'should count neighbors' do
      expect(Creature.neighbors_of(a.location).all).to eq([b])
      expect(Creature.neighbors_of(b.location).all).to eq([a,c])
      expect(Creature.neighbors_of(c.location).all).to eq([b])
      expect(Creature.neighbors_of(d.location).all).to eq([])
    end

    it 'should handle edge cases' do
      expect(Creature.neighbors_of(coord(1,1)).all).to eq([a,b,c])
    end
  end
end

describe CreateWorldCommand do
  include Gol::DimensionHelpers

  let(:sim) { Metacosm::Simulation.current }
  let(:dimensions) { dim(10,10) }

  subject(:command) do
    CreateWorldCommand.create(
      world_id: 'world_id',
      dimensions: dimensions
    )
  end

  it 'should build a world' do
    expect{sim.apply(command)}.to change{World.count}.by(1)
    expect(World.find('world_id').dimensions).to eq(dimensions)
  end
end

describe IterateCommand do
  include Gol::LocationHelpers
  include Gol::DimensionHelpers

  before(:each) { PassiveRecord.drop_all }
  let(:red) { Gol::Color.new(255,255,0,0) }
  let(:blue) { Gol::Color.new(255,0,0,255) }
  let(:purple) { Gol::Color.new(255,42,0,42) }

  let(:iteration_event) do
    IterationEvent.create(
      world_id: 'world_id',
      locations_and_colors: {
        coord(2,2) => red,
        coord(3,2) => red,
        coord(1,2) => red,
      }
    )
  end

  let!(:world) do
    World.create id: 'world_id', dimensions: dim(10,10)
  end

  context 'iteration' do
    subject(:command) { IterateCommand.create(world_id: 'world_id') }
    before do
      world.create_creature location: coord(2,1), color: red
      world.create_creature location: coord(2,2), color: red
      world.create_creature location: coord(2,3), color: red
    end

    it { is_expected.to trigger_event(iteration_event) }
  end
end
