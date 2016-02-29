require 'spec_helper'
require 'pry'
require 'gol'

xdescribe World do
  let(:world) { World.create }
  xit 'should build a 2-d field' do
    expect(world.inhabitants.all).to eq([Inhabitant.first])
    expect(world.inhabitant_locations).to eq([Inhabitant.first.location])
  end

  xdescribe "#birth_inhabitant_at" do
    it 'should create a new inhabitant' do
      expect{ world.birth_inhabitant_at(coord(4,5)) }.to change{ world.inhabitants.count }.by(1)
    end
  end

  xdescribe "#kill_inhabitant_at" do
    it 'should destroy an inhabitant' do
      world.birth_inhabitant_at(coord(4,5))
      expect{ world.kill_inhabitant_at(coord(4,5)) }.to change{ world.inhabitants.count }.by(-1)
    end
  end
end

describe Inhabitant do
  before(:each) { PassiveRecord.drop_all }
  let(:world) { World.create(dimensions: dimensions) }
  let(:pos) { coord(0,0) }
  let(:dimensions) { [10,10] }
  subject(:inhabitant) { world.create_inhabitant(location: pos) }

  describe 'instance attributes' do
    it 'should have a location' do
      expect(inhabitant.location).to eq(pos)
    end
  end

  describe 'class methods' do
    it 'should have an .at scope' do
      expect(inhabitant).to eq(Inhabitant.at(coord(0,0)).first)
    end
  end

  context 'counting neighbors' do
    let!(:a) { Inhabitant.create(location: coord(0,0), world: world) }
    let!(:b) { Inhabitant.create(location: coord(0,1), world: world) }
    let!(:c) { Inhabitant.create(location: coord(0,2), world: world) }
    let!(:d) { Inhabitant.create(location: coord(3,3), world: world) }

    it 'should count neighbors' do
      expect(Inhabitant.neighbors_of(a.location)).to eq([b])
      expect(Inhabitant.neighbors_of(b.location)).to eq([a,c])
      expect(Inhabitant.neighbors_of(c.location)).to eq([b])
      expect(Inhabitant.neighbors_of(d.location)).to eq([])
    end

    it 'should handle edge cases' do
      expect(Inhabitant.neighbors_of(coord(1,1))).to eq([a,b,c])
    end
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
  before(:each) { PassiveRecord.drop_all }
  let(:iteration_event) do
    IterationEvent.create(
      world_id: 'world_id', 
      locations: [
        coord(2,2),
        coord(3,2),
        coord(1,2),
      ]
    )
  end

  let!(:world) do
    World.create id: 'world_id', dimensions: [10,10]
  end

  context 'iteration' do
    subject(:command) { IterateCommand.create(world_id: 'world_id') }
    before do
      world.create_inhabitant location: coord(2,1)
      world.create_inhabitant location: coord(2,2)
      world.create_inhabitant location: coord(2,3)
    end

    it { is_expected.to trigger_event(iteration_event) }
  end

  context 'gol rules' do
    let(:inhabitant_died) do
      InhabitantDestroyedEvent.create(location: pos)
    end

    let(:pos) do
      coord(1,1)
    end

    let(:inhabitant) do
      Inhabitant.create(location: pos)
    end

    xit 'should trigger deaths' do
      Inhabitant.create(location: pos)
      expect(command).to trigger_event(inhabitant_died)
    end
  end
end
