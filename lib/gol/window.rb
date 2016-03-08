module Gol
  class ApplicationWindow < Gosu::Window
    include DimensionHelpers
    SCALE = 16

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
          dimensions: dim((self.width/SCALE).to_i, (self.height/SCALE).to_i)
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
end
