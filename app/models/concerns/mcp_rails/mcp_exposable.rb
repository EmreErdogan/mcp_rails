# frozen_string_literal: true

module McpRails
  # Concern for exposing ActiveRecord models to MCP
  #
  # Usage:
  #   class Product < ApplicationRecord
  #     include McpRails::McpExposable
  #     expose_to_mcp
  #   end
  #
  # Advanced usage:
  #   class Product < ApplicationRecord
  #     include McpRails::McpExposable
  #     expose_to_mcp attributes: [:id, :name, :price], read_only: false
  #   end
  module McpExposable
    extend ActiveSupport::Concern

    class_methods do
      # Register this model with MCP server
      # Options:
      #   - attributes: Array of attribute names to expose (default: all columns)
      #   - read_only: If true, only list/get tools are created (default: false)
      def expose_to_mcp(options = {})
        # Store configuration for later use
        @mcp_exposure_config = {
          attributes: options[:attributes],
          read_only: options.fetch(:read_only, false)
        }

        # Register with global MCP registry
        McpRails::Registry.register(self, @mcp_exposure_config)
      end

      def mcp_exposure_config
        @mcp_exposure_config || {}
      end
    end
  end
end