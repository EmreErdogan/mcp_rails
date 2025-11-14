require_relative "lib/mcp_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "mcp_rails"
  spec.version     = McpRails::VERSION
  spec.authors     = [ "Emre Erdogan" ]
  spec.email       = [ "emre@emreerdogan.net" ]
  spec.homepage    = "https://github.com/EmreErdogan/mcp_rails"
  spec.summary     = "Model Context Protocol (MCP) support for Rails applications"
  spec.description = "Expose Rails models via MCP for AI assistants. Automatically generate CRUD operations for your ActiveRecord models, making them accessible through the Model Context Protocol."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/EmreErdogan/mcp_rails"
  spec.metadata["changelog_uri"] = "https://github.com/EmreErdogan/mcp_rails/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "mcp", "~> 0.4.0"
end
