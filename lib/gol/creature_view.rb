module Gol
  class CreatureView < Metacosm::View
    belongs_to :world_view
    attr_accessor :world_id, :creature_id, :color, :location

    # def world_view_id
    #   field_view.world_view_id
    # end

    def render(window, alpha=240)
      return unless location
      gosu_color = color.to_gosu
      gosu_color.alpha = alpha

      w,h = *world_view.dimensions
      cell_width = window.width / w
      cell_height = window.height / h
      scaled_location = location.scale(cell_width, cell_height)

      x,y = *scaled_location
      window.draw_quad(x, y, gosu_color,
                       x, y+cell_height, gosu_color,
                       x+cell_width, y, gosu_color,
                       x+cell_width, y+cell_height, gosu_color)
    end
  end
end
