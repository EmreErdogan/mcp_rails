# frozen_string_literal: true

# MCP Rails Configuration
# Configure the Model Context Protocol server for your Rails application

McpRails.configure do |config|
  # Server identification
  config.server_name = "<%= Rails.application.class.module_parent_name.underscore %>_mcp"
  config.server_version = "1.0.0"
  config.server_instructions = "Rails API for <%= Rails.application.class.module_parent_name %> exposed via MCP"

  # Authentication strategy
  # Options: :none, :token, :api_key
  # WARNING: :none should ONLY be used in development!
  config.auth_strategy = Rails.env.production? ? :token : :none

  # Authentication credentials
  # For production, use Rails credentials or environment variables:
  # config.auth_token = Rails.application.credentials.mcp[:auth_token]
  # config.auth_token = ENV['MCP_AUTH_TOKEN']
  config.auth_token = ENV['MCP_AUTH_TOKEN']
  config.api_key = ENV['MCP_API_KEY']

  # Request logging
  # Enable detailed logging of MCP requests (disable in production for performance)
  config.log_requests = !Rails.env.production?

  # Rate limiting (optional, requires additional middleware)
  # config.rate_limit = 100  # requests per minute
end

# Example: Expose your models to MCP
# Add this to your model files:
#
# class Product < ApplicationRecord
#   include McpRails::McpExposable
#   expose_to_mcp
# end
#
# Advanced options:
# expose_to_mcp attributes: [:id, :name, :price], read_only: false