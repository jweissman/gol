module Gol
  class HistoryView < Metacosm::View
    belongs_to :world
    has_many :field_views

    def render(window)
      field_views.each_with_index do |field_view, i|
        # depth = 
        field_view.render(window) #, :alpha => depth)
      end
    end
  end
end
