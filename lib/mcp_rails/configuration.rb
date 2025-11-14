# frozen_string_literal: true

module McpRails
  class Configuration
    attr_accessor :auth_strategy, :auth_token, :api_key, :rate_limit,
                  :log_requests, :server_name, :server_version,
                  :server_instructions

    def initialize
      @auth_strategy = Rails.env.production? ? :token : :none
      @auth_token = ENV['MCP_AUTH_TOKEN']
      @api_key = ENV['MCP_API_KEY']
      @rate_limit = nil
      @log_requests = !Rails.env.production?
      @server_name = "rails-mcp-server"
      @server_version = "1.0.0"
      @server_instructions = "A Rails API exposed via MCP. Use the available tools to manage data."
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def server
      @server ||= begin
        require 'mcp'

        MCP::Server.new(
          name: configuration.server_name,
          version: configuration.server_version,
          instructions: configuration.server_instructions
        )
      end
    end

    def reset!
      @configuration = nil
      @server = nil
      Registry.clear!
    end
  end
end