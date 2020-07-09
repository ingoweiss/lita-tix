require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita-non-command-only"
require "lita/handlers/rally"
require "lita/formatters/base_formatter"
require "lita/formatters/story_formatter"
require "lita/formatters/defect_formatter"
require "lita/formatters/task_formatter"
require "lita/formatters/project_formatter"
require "rally_rest_api"
