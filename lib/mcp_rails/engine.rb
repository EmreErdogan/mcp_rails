module McpRails
  class Engine < ::Rails::Engine
    isolate_namespace McpRails

    # Configure exception reporting
    initializer "mcp_rails.configure_mcp" do |app|
      MCP.configure do |config|
        config.exception_reporter = ->(exception) {
          Rails.logger.error "MCP Exception: #{exception.class} - #{exception.message}"
          Rails.logger.error exception.backtrace.join("\n")
        }
      end if defined?(MCP)
    end

    # Auto-register models on each request (in development) or once (in production)
    config.to_prepare do
      # Clear existing registrations on reload
      McpRails::Registry.clear!

      # Always eager load models to ensure they register with MCP
      # This is necessary because models need to be loaded for expose_to_mcp to be called
      Rails.application.eager_load!

      # Setup server with registered models
      McpRails::Registry.setup_server(McpRails.server)

      Rails.logger.info "MCP Server initialized with #{McpRails.server.tools.count} tools"
      Rails.logger.info "Registered tools: #{McpRails.server.tools.keys.join(', ')}" if McpRails.configuration.log_requests
    end

    # Add engine's app directories to autoload paths
    config.autoload_paths += Dir[Engine.root.join("app", "mcp", "**/")]

    # Explicitly require MCP tools
    initializer "mcp_rails.load_app_classes" do |app|
      require Engine.root.join("app/mcp/tools/base_crud_tools")
    end
  end
end
