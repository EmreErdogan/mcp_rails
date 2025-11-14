# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module McpRails
  # StdioServer provides a bridge between stdio (used by Claude Code) and HTTP (used by Rails)
  # This allows the MCP Rails server to work with both HTTP clients and stdio-based clients like Claude Code
  class StdioServer
    def initialize(base_url: nil, debug: false)
      @base_url = base_url || default_base_url
      @debug = debug || ENV['MCP_DEBUG']
      @running = false
    end

    # Main entry point - runs the stdio server loop
    def run
      setup_environment
      log "MCP Rails stdio server starting..."
      log "Connecting to: #{@base_url}"

      @running = true

      while @running
        begin
          # Read JSON-RPC request from stdin
          line = STDIN.gets
          break unless line

          request = JSON.parse(line.strip)
          log "Received: #{request['method']}" if @debug

          # Forward to HTTP endpoint
          response = forward_to_http(request)

          # Write response to stdout
          STDOUT.puts response.to_json
          STDOUT.flush

        rescue JSON::ParserError => e
          log "JSON parse error: #{e.message}"
          send_error(-32700, "Parse error: #{e.message}")
        rescue Interrupt
          log "Received interrupt signal, shutting down..."
          @running = false
        rescue => e
          log "Error: #{e.message}"
          log e.backtrace.join("\n") if @debug
          send_error(-32603, "Internal error: #{e.message}")
        end
      end

      log "MCP Rails stdio server stopped"
    rescue => e
      log "Fatal error: #{e.message}"
      log e.backtrace.join("\n")
      exit(1)
    end

    # Alternative method name for compatibility
    def run_stdio
      run
    end

    private

    def setup_environment
      # Ensure Rails is loaded
      Rails.application.eager_load! if defined?(Rails)
    end

    def default_base_url
      host = ENV['RAILS_HOST'] || 'localhost'
      port = ENV['PORT'] || ENV['RAILS_PORT'] || 3000
      "http://#{host}:#{port}/mcp/handle"
    end

    def forward_to_http(request)
      uri = URI(@base_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      # Set reasonable timeouts
      http.open_timeout = 10
      http.read_timeout = 30

      req = Net::HTTP::Post.new(uri.path)
      req['Content-Type'] = 'application/json'
      req['Accept'] = 'application/json'

      # Skip CSRF for internal requests
      req['X-MCP-Internal'] = 'true'

      # Forward authentication headers if configured
      if McpRails.configuration.auth_strategy == :token && McpRails.configuration.auth_token
        req['Authorization'] = "Bearer #{McpRails.configuration.auth_token}"
      elsif McpRails.configuration.auth_strategy == :api_key && McpRails.configuration.api_key
        req['X-API-Key'] = McpRails.configuration.api_key
      end

      req.body = request.to_json

      response = http.request(req)

      if response.code == '200'
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          log "Failed to parse HTTP response: #{e.message}"
          log "Response body: #{response.body}" if @debug
          {
            jsonrpc: "2.0",
            id: request['id'],
            error: {
              code: -32603,
              message: "Invalid response from server"
            }
          }
        end
      else
        log "HTTP Error #{response.code}: #{response.body}" if @debug
        {
          jsonrpc: "2.0",
          id: request['id'],
          error: {
            code: -32603,
            message: "HTTP error: #{response.code}"
          }
        }
      end
    rescue Errno::ECONNREFUSED => e
      log "Connection refused: Make sure Rails server is running on #{uri}"
      {
        jsonrpc: "2.0",
        id: request['id'],
        error: {
          code: -32603,
          message: "Connection refused: Rails server not accessible at #{uri}"
        }
      }
    rescue => e
      log "HTTP forward error: #{e.message}"
      {
        jsonrpc: "2.0",
        id: request['id'],
        error: {
          code: -32603,
          message: "Connection error: #{e.message}"
        }
      }
    end

    def send_error(code, message)
      error = {
        jsonrpc: "2.0",
        id: nil,
        error: {
          code: code,
          message: message
        }
      }
      STDOUT.puts error.to_json
      STDOUT.flush
    end

    def log(message)
      STDERR.puts "[MCP Rails] #{message}"
    end
  end
end