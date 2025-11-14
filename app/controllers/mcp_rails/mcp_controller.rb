# frozen_string_literal: true

module McpRails
  # MCP Controller
  # Handles Model Context Protocol requests from AI clients
  #
  # This controller receives JSON-RPC 2.0 messages from MCP clients,
  # processes them using the MCP_SERVER instance, and returns responses.
  class McpController < ApplicationController
    skip_before_action :verify_authenticity_token if respond_to?(:verify_authenticity_token)

    before_action :authenticate_request! if McpRails.configuration.auth_strategy != :none

    # POST /mcp
    # Main endpoint for handling MCP requests
    def handle
      request_body = request.body.read

      # Log the incoming request for debugging
      Rails.logger.info "MCP Request: #{request_body}" if McpRails.configuration.log_requests

      # Process the request through the MCP server
      result = McpRails.server.handle_json(request_body)

      # Log the response for debugging
      Rails.logger.info "MCP Response: #{result}" if McpRails.configuration.log_requests

      # Return the response as JSON
      render json: result
    rescue StandardError => e
      # Handle any errors that occur during processing
      Rails.logger.error "MCP Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        jsonrpc: "2.0",
        error: {
          code: -32603,
          message: "Internal error: #{e.message}"
        },
        id: nil
      }, status: :internal_server_error
    end

    private

    def authenticate_request!
      case McpRails.configuration.auth_strategy
      when :token
        authenticate_with_token!
      when :api_key
        authenticate_with_api_key!
      end
    end

    def authenticate_with_token!
      token = request.headers['Authorization']&.gsub(/^Bearer\s+/, '')

      unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, McpRails.configuration.auth_token.to_s)
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    def authenticate_with_api_key!
      api_key = request.headers['X-API-Key']

      unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, McpRails.configuration.api_key.to_s)
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end