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
          # This script runs the MCP server in stdio mode for Claude Desktop

          require_relative '../config/environment'

          Rails.application.eager_load!
          McpRails.server.run_stdio
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