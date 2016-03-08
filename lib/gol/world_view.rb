module Gol
  class WorldView < Metacosm::View
    attr_accessor :world_id, :dimensions
    # has_one :field_view
    has_many :creature_views #, :through => :field_view

    def render(window)
      creature_views.each do |creature_view|
        creature_view.render(window)
      end
      # if field_view
      #   field_view.render(window)
      # else
      #   puts "[WARN] field view is nil!"
      # end
    end
  end
end
