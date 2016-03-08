module Gol
  class CreateWorldCommand < Metacosm::Command
    attr_accessor :world_id, :dimensions, :generate
  end
end
