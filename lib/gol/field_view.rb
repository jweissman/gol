module Gol
  class FieldView < Metacosm::View
    has_many :creature_views
    belongs_to :world_view

    def render(window)
      creature_views.each do |creature_view|
        creature_view.render(window)
      end
    end

    def dimensions
      world_view.dimensions
    end
  end
end
