# frozen_string_literal: true

module McpRails
  module Tools
    # Base class for automatically generating CRUD tools for ActiveRecord models
    # Usage: BaseCrudTools.generate(Product)
    #
    # This will create 5 tools:
    # - list_{model_name_plural}
    # - get_{model_name}
    # - create_{model_name}
    # - update_{model_name}
    # - delete_{model_name}
    class BaseCrudTools
      class << self
        def generate(model_class, server, options = {})
          model_name = model_class.name.underscore
          model_name_plural = model_name.pluralize

          # Extract options with defaults
          attributes = options[:attributes] || default_attributes(model_class)
          read_only = options[:read_only] || false

          # Register LIST tool
          register_list_tool(server, model_class, model_name_plural, attributes)

          # Register GET tool
          register_get_tool(server, model_class, model_name, attributes)

          # Skip write operations if read_only
          unless read_only
            register_create_tool(server, model_class, model_name, attributes)
            register_update_tool(server, model_class, model_name, attributes)
            register_delete_tool(server, model_class, model_name)
          end
        end

        private

        def default_attributes(model_class)
          # Get all column names except timestamps and internal Rails columns
          model_class.column_names.reject do |col|
            %w[created_at updated_at].include?(col)
          end
        end

        def writable_attributes(attributes)
          # Remove id and timestamps from writable attributes
          attributes.reject { |attr| %w[id created_at updated_at].include?(attr) }
        end

        def register_list_tool(server, model_class, model_name_plural, attributes)
          # Capture attributes in closure
          attrs = attributes.dup

          server.define_tool(
            name: "list_#{model_name_plural}",
            description: "List all #{model_name_plural}",
            input_schema: {
              type: "object",
              properties: {},
              required: []
            }
          ) do |server_context: nil, **args|
            records = model_class.all.map do |record|
              attrs.each_with_object({}) { |attr, hash| hash[attr] = record.send(attr) }
            end

            MCP::Tool::Response.new([{
              type: "text",
              text: JSON.pretty_generate(records)
            }])
          end
        end

        def register_get_tool(server, model_class, model_name, attributes)
          attrs = attributes.dup
          name_camelized = model_name.camelize

          server.define_tool(
            name: "get_#{model_name}",
            description: "Get a specific #{model_name} by ID",
            input_schema: {
              type: "object",
              properties: {
                id: { type: "integer", description: "#{name_camelized} ID" }
              },
              required: ["id"]
            }
          ) do |server_context: nil, **args|
            record = model_class.find_by(id: args[:id])

            if record
              data = attrs.each_with_object({}) { |attr, hash| hash[attr] = record.send(attr) }
              MCP::Tool::Response.new([{
                type: "text",
                text: JSON.pretty_generate(data)
              }])
            else
              MCP::Tool::Response.new(
                [{
                  type: "text",
                  text: "#{name_camelized} not found with ID: #{args[:id]}"
                }],
                error: true
              )
            end
          end
        end

        def register_create_tool(server, model_class, model_name, attributes)
          writable_attrs = writable_attributes(attributes)
          properties = generate_schema_properties(model_class, writable_attrs)
          attrs = attributes.dup
          name_camelized = model_name.camelize
          writable_syms = writable_attrs.map(&:to_sym)

          server.define_tool(
            name: "create_#{model_name}",
            description: "Create a new #{model_name}",
            input_schema: {
              type: "object",
              properties: properties,
              required: writable_attrs
            }
          ) do |server_context: nil, **args|
            begin
              record = model_class.create!(args.slice(*writable_syms))
              data = attrs.each_with_object({}) { |attr, hash| hash[attr] = record.send(attr) }

              MCP::Tool::Response.new([{
                type: "text",
                text: "#{name_camelized} created successfully:\n#{JSON.pretty_generate(data)}"
              }])
            rescue ActiveRecord::RecordInvalid => e
              MCP::Tool::Response.new(
                [{
                  type: "text",
                  text: "Failed to create #{model_name}: #{e.message}"
                }],
                error: true
              )
            end
          end
        end

        def register_update_tool(server, model_class, model_name, attributes)
          writable_attrs = writable_attributes(attributes)
          properties = generate_schema_properties(model_class, writable_attrs)
          name_camelized = model_name.camelize
          properties[:id] = { type: "integer", description: "#{name_camelized} ID" }
          attrs = attributes.dup
          writable_syms = writable_attrs.map(&:to_sym)

          server.define_tool(
            name: "update_#{model_name}",
            description: "Update an existing #{model_name}",
            input_schema: {
              type: "object",
              properties: properties,
              required: ["id"]
            }
          ) do |server_context: nil, **args|
            record = model_class.find_by(id: args[:id])

            if record
              begin
                record.update!(args.slice(*writable_syms))
                data = attrs.each_with_object({}) { |attr, hash| hash[attr] = record.send(attr) }
                MCP::Tool::Response.new([{
                  type: "text",
                  text: "#{name_camelized} updated successfully:\n#{JSON.pretty_generate(data)}"
                }])
              rescue ActiveRecord::RecordInvalid => e
                MCP::Tool::Response.new(
                  [{
                    type: "text",
                    text: "Failed to update #{model_name}: #{e.message}"
                  }],
                  error: true
                )
              end
            else
              MCP::Tool::Response.new(
                [{
                  type: "text",
                  text: "#{name_camelized} not found with ID: #{args[:id]}"
                }],
                error: true
              )
            end
          end
        end

        def register_delete_tool(server, model_class, model_name)
          server.define_tool(
            name: "delete_#{model_name}",
            description: "Delete a #{model_name}",
            input_schema: {
              type: "object",
              properties: {
                id: { type: "integer", description: "#{model_name.camelize} ID" }
              },
              required: ["id"]
            }
          ) do |server_context: nil, **args|
            record = model_class.find_by(id: args[:id])

            if record
              record.destroy!
              MCP::Tool::Response.new([{
                type: "text",
                text: "#{model_name.camelize} deleted successfully (ID: #{args[:id]})"
              }])
            else
              MCP::Tool::Response.new(
                [{
                  type: "text",
                  text: "#{model_name.camelize} not found with ID: #{args[:id]}"
                }],
                error: true
              )
            end
          end
        end

        def serialize_record(record, attributes)
          attributes.each_with_object({}) do |attr, hash|
            hash[attr] = record.send(attr)
          end
        end

        def generate_schema_properties(model_class, attributes)
          attributes.each_with_object({}) do |attr, hash|
            column = model_class.columns_hash[attr]
            hash[attr.to_sym] = {
              type: map_column_type(column&.type),
              description: "#{attr.humanize}"
            }
          end
        end

        def map_column_type(column_type)
          case column_type
          when :integer, :bigint
            "integer"
          when :float, :decimal
            "number"
          when :boolean
            "boolean"
          when :date, :datetime, :time
            "string"
          else
            "string"
          end
        end
      end
    end
  end
end