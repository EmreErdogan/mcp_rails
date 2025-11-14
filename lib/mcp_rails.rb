require "mcp_rails/version"
require "mcp_rails/configuration"
require "mcp_rails/tools/base_crud_tools"
require "mcp_rails/registry"
require "mcp_rails/stdio_server"
require "mcp_rails/engine"

module McpRails
  class Error < StandardError; end

  # Auto-include McpExposable in ActiveRecord
  ActiveSupport.on_load(:active_record) do
    require_dependency "mcp_rails/mcp_exposable"
    include McpRails::McpExposable
  end
end
