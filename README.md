# MCP Rails

MCP Rails is a Ruby on Rails engine that enables Model Context Protocol (MCP) support for your Rails applications. It allows you to expose your ActiveRecord models to AI assistants like Claude, automatically generating CRUD operations that can be accessed via MCP.

## Features

- 🚀 **Automatic CRUD Generation** - Instantly expose your models with list, get, create, update, and delete operations
- 🔒 **Built-in Authentication** - Support for token and API key authentication strategies
- 🎯 **Selective Exposure** - Choose which models and attributes to expose
- 📝 **Read-Only Mode** - Optionally expose models as read-only
- 🔧 **Easy Configuration** - Simple DSL for model configuration
- 🏗️ **Rails Engine** - Clean, isolated namespace with easy installation

## Installation

Add this line to your application's Gemfile:

```ruby
# Using GitHub (until published to RubyGems)
gem "mcp_rails", github: "EmreErdogan/mcp_rails"

# Or using local path for development
gem "mcp_rails", path: "../mcp_rails"
```

Then execute:

```bash
$ bundle install
$ rails generate mcp_rails:install
```

## Quick Start

### 1. Expose Your Models

Add the following to any ActiveRecord model you want to expose:

```ruby
class Product < ApplicationRecord
  include McpRails::McpExposable
  expose_to_mcp
end

class Customer < ApplicationRecord
  include McpRails::McpExposable
  expose_to_mcp attributes: [:id, :name, :email]
end

class Order < ApplicationRecord
  include McpRails::McpExposable
  expose_to_mcp read_only: true
end
```

### 2. Configure Authentication (Optional)

Edit `config/initializers/mcp_rails.rb`:

```ruby
McpRails.configure do |config|
  config.server_name = "my_app_mcp"
  config.server_version = "1.0.0"

  # For production
  config.auth_strategy = :token
  config.auth_token = Rails.application.credentials.mcp[:auth_token]
end
```

### 3. Set Up Claude Desktop

Copy the generated `.mcp.json.example` to your Claude Desktop configuration:

**macOS:**
```bash
cp .mcp.json.example ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Windows:**
```cmd
copy .mcp.json.example %APPDATA%\Claude\claude_desktop_config.json
```

### 4. Test Your Setup

```bash
# In Rails console
rails console

McpRails.server.tools.keys
# => ["list_products", "get_product", "create_product", "update_product", "delete_product", ...]
```

## Configuration Options

### Model Exposure Options

```ruby
class Product < ApplicationRecord
  include McpRails::McpExposable

  # Expose all attributes with all CRUD operations
  expose_to_mcp

  # Expose specific attributes only
  expose_to_mcp attributes: [:id, :name, :price, :description]

  # Read-only exposure (only list and get operations)
  expose_to_mcp read_only: true

  # Combine options
  expose_to_mcp attributes: [:id, :name], read_only: true
end
```

### Server Configuration

```ruby
McpRails.configure do |config|
  # Server identification
  config.server_name = "my_app_mcp"
  config.server_version = "1.0.0"
  config.server_instructions = "Custom instructions for AI assistants"

  # Authentication
  config.auth_strategy = :token  # Options: :none, :token, :api_key
  config.auth_token = ENV['MCP_AUTH_TOKEN']
  config.api_key = ENV['MCP_API_KEY']

  # Logging
  config.log_requests = true  # Log all MCP requests

  # Rate limiting (requires additional middleware)
  config.rate_limit = 100  # requests per minute
end
```

## Authentication Strategies

### Token Authentication

```ruby
config.auth_strategy = :token
config.auth_token = "your-secret-token"
```

Clients must include the token in the Authorization header:
```
Authorization: Bearer your-secret-token
```

### API Key Authentication

```ruby
config.auth_strategy = :api_key
config.api_key = "your-api-key"
```

Clients must include the API key in the X-API-Key header:
```
X-API-Key: your-api-key
```

### No Authentication (Development Only)

```ruby
config.auth_strategy = :none  # ⚠️ Use only in development!
```

## Generated Tools

For each exposed model, MCP Rails generates the following tools:

| Tool | Description | Example |
|------|-------------|---------|
| `list_{model}s` | List all records | `list_products` |
| `get_{model}` | Get a single record by ID | `get_product` |
| `create_{model}` | Create a new record | `create_product` |
| `update_{model}` | Update an existing record | `update_product` |
| `delete_{model}` | Delete a record | `delete_product` |

## Advanced Usage

### Custom Tool Names

Coming soon: Support for custom tool naming conventions.

### Callbacks and Validations

All ActiveRecord validations and callbacks work as expected:

```ruby
class Product < ApplicationRecord
  include McpRails::McpExposable
  expose_to_mcp

  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }

  before_save :calculate_tax
  after_create :send_notification
end
```

### Scoping and Permissions

Coming soon: Support for user-scoped queries and permission systems.

## Development

After checking out the repo, run:

```bash
cd mcp_rails
bundle install
rails test
```

To test in a Rails application:

```ruby
# In your Rails app's Gemfile
gem 'mcp_rails', path: '/path/to/mcp_rails'
```

## Testing the MCP Server

You can test the MCP server directly:

```bash
# Run the server in stdio mode
cd your_rails_app
ruby bin/mcp_server

# The server expects JSON-RPC messages on stdin
# Send a test message to list tools
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | ruby bin/mcp_server
```

## Troubleshooting

### "NameError: uninitialized constant McpRails::McpExposable"

Make sure to restart your Rails server after installation:
```bash
rails restart
```

### Tools not showing up

Ensure your models are being loaded:
```ruby
# In Rails console
Rails.application.eager_load!
McpRails::Registry.models
```

### Authentication errors

Check your authentication configuration:
```ruby
# In Rails console
McpRails.configuration.auth_strategy
McpRails.configuration.auth_token
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

Built with ❤️ for the Rails and AI community. Special thanks to Anthropic for creating the Model Context Protocol.