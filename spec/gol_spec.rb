require 'spec_helper'
require 'pry'
require 'gol'

xdescribe World do
  let(:world) { World.create }
  it 'should build a 2-d field' do
    expect(world.inhabitants.all).to eq([Inhabitant.first])
    expect(world.inhabitant_locations).to eq([Inhabitant.first.location])
  end
end

describe Inhabitant do
  before(:each) { PassiveRecord.drop_all }
  let(:world) { World.create }
  let(:location) { [0,0] }
  subject(:inhabitant) { world.create_inhabitant location: location }

  it 'should have a location' do
    expect(inhabitant.location).to eq(location)
  end

  it 'should compute distance' do
    expect(inhabitant.distance_to([3,4])).to eq(5)
  end

  it 'should track cohort' do
    a = Inhabitant.create(location: [0,0], world: world)
    b = Inhabitant.create(location: [0,1], world: world)

    expect(a.cohort).to eq([b])
    expect(b.cohort).to eq([a])
  end

  it 'should count neighbors' do
    a = Inhabitant.create(location: [0,0], world: world)
    b = Inhabitant.create(location: [0,1], world: world)
    c = Inhabitant.create(location: [0,2], world: world)
    d = Inhabitant.create(location: [3,3], world: world)

    expect(a.neighbors).to eq([b])
    expect(b.neighbors).to eq([a,c])
    expect(c.neighbors).to eq([b])
    expect(d.neighbors).to eq([])
  end
end

describe CreateWorldCommand do
  let(:sim) { Simulation.current }
  let(:dimensions) { [10,10] }

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
  let(:iteration_event) do
    IterationEvent.create(world_id: 'world_id', locations: [])
  end

  before do
    World.create id: 'world_id', dimensions: [10,10]
  end

  subject(:command) { IterateCommand.create(world_id: 'world_id') }
  it { is_expected.to trigger_event(iteration_event) }

  it 'should trigger iteration' do
    expect(command).to trigger_events(iteration_event)
  end
end
