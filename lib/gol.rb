require 'metacosm'
require 'parallel'
require 'gosu'
require 'pry'

require 'gol/version'

require 'gol/color'
require 'gol/location'
require 'gol/dimensions'
require 'gol/distance'

require 'gol/commands/create_world_command'
require 'gol/commands/populate_world_command'
require 'gol/commands/iterate_command'

require 'gol/events/world_created_event'
require 'gol/events/world_populated_event'
require 'gol/events/creature_created_event'
require 'gol/events/creature_destroyed_event'
require 'gol/events/iteration_event'

require 'gol/handlers/create_world_command_handler'
require 'gol/handlers/populate_world_command_handler'
require 'gol/handlers/iterate_command_handler'

require 'gol/listeners/world_created_event_listener'
require 'gol/listeners/world_populated_event_listener'
require 'gol/listeners/creature_created_event_listener'
require 'gol/listeners/creature_destroyed_event_listener'
require 'gol/listeners/iteration_event_listener'

require 'gol/creature'
require 'gol/world'

require 'gol/creature_view'
require 'gol/field_view'
require 'gol/world_view'

require 'gol/window'

# TODO move to metacosm
Thread.abort_on_exception=true
