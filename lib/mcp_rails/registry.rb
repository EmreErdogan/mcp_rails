# frozen_string_literal: true

module McpRails
  # Global registry for MCP-exposed models
  class Registry
    class << self
      def models
        @models ||= []
      end

      def register(model_class, config)
        models << { model: model_class, config: config }
      end

      def setup_server(server = McpRails.server)
        models.each do |entry|
          model_class = entry[:model]
          config = entry[:config]

          # Generate tools
          McpRails::Tools::BaseCrudTools.generate(model_class, server, config)

          # Generate resources if defined
          if defined?(McpRails::Resources::BaseCrudResources)
            McpRails::Resources::BaseCrudResources.generate(model_class, server, config)
          end
        end
      end

      def clear!
        @models = []
      end

      def registered?(model_class)
        models.any? { |entry| entry[:model] == model_class }
      end
    end
  end
end