require 'rspec'
require 'json-schema'

module JSON
  module SchemaMatchers
    RSpec.configure do |c|
      c.add_setting :json_schemas, default: {}
    end

    class MatchJsonSchemaMatcher
      def initialize(schema_name, validation_opts = {})
        @schema_name = schema_name
        @validation_opts = validation_opts
        @errors = []
      end

      def matches?(actual)
        @actual = actual

        schema = schema_for_name(@schema_name)
        if schema.nil?
          @errors = ["No schema defined for #{@schema_name}. Available schemas are #{RSpec.configuration.json_schemas.keys}."]
          return false
        end
        @errors = JSON::Validator.fully_validate(schema_for_name(@schema_name), @actual, @validation_opts)

        if @errors.any?
          @errors.unshift("Expected JSON object to match schema identified by #{@schema_name}, #{@errors.count} errors in validating")
          return false
        else
          return true
        end
      end

      def inspect
        if @errors.any?
          failure_message
        else
          super
        end
      end

      alias_method :to_s, :inspect

      def ===(other)
        matches?(other)
      end

      def failure_message
        @errors.join("\n")
      end

      def failure_message_when_negated
        "Expected JSON object not to match schema identified by #{@schema_name}"
      end

      def description
        if @errors.any?
          # ignore the preamble in a diff
          @errors[1..-1].join("\n")
        else
          "match JSON schema identified by #{@schema_name}"
        end
      end

      def schema_for_name(schema)
        RSpec.configuration.json_schemas[schema]
      end
    end

    def match_json_schema(schema_name, validation_opts = {})
      MatchJsonSchemaMatcher.new(schema_name, validation_opts)
    end

    alias_method :object_matching_schema, :match_json_schema
  end
end
