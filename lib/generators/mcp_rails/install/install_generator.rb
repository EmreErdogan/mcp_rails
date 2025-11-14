# frozen_string_literal: true

require 'rails/generators/base'

module McpRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def copy_initializer
        template "mcp_rails_initializer.rb", "config/initializers/mcp_rails.rb"
      end

      def copy_mcp_json_example
        template "mcp.json", ".mcp.json.example"
      end

      def add_route
        route 'mount McpRails::Engine => "/mcp"'
      end

      def create_mcp_runner
        create_file "bin/mcp_server", <<~RUBY
          #!/usr/bin/env ruby
          # This script runs the MCP server in stdio mode for Claude Desktop/Code
          #
          # This creates a bridge between stdio (used by Claude) and HTTP (used by Rails)
          # Make sure your Rails server is running before connecting from Claude

          require_relative '../config/environment'

          # Start the stdio server
          # It will automatically connect to your Rails server at http://localhost:3000/mcp/handle
          # You can override the URL with environment variables:
          #   RAILS_HOST=example.com RAILS_PORT=4000 bin/mcp_server

          McpRails.stdio_server.run
        RUBY

        chmod "bin/mcp_server", 0755
      end

      def display_readme
        readme "README" if behavior == :invoke
      end

      private

      def rails_6_or_newer?
        Rails::VERSION::MAJOR >= 6
      end
    end
  end
end