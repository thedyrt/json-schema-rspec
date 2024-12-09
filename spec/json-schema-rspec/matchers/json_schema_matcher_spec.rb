require 'spec_helper'

describe JSON::SchemaMatchers::MatchJsonSchemaMatcher do
  let(:valid_json)    { '"hello world"' }
  let(:invalid_json)  { '{"key": "value"}' }
  let(:inline_schema) { '{"type": "string"}' }

  context 'without valid schema_name' do
    let(:unconfigured_schema) { :unconfigured_schema }
    specify 'matches fail' do
      expect(valid_json).not_to match_json_schema(unconfigured_schema)
    end

    specify 'strict matches fail' do
      expect(valid_json).not_to match_json_schema(unconfigured_schema, strict: true)
    end

    specify 'assigns a failure message' do
      matcher = match_json_schema(unconfigured_schema)
      expect(matcher.matches?(valid_json)).to eq(false)
      expect(matcher.failure_message)
        .to match(/^No schema defined for #{unconfigured_schema}/)
        .and match(/Available schemas are/)
    end
  end

  context 'when being used as a argument matcher' do
    before :each do
      RSpec.configuration.json_schemas[:inline_schema] = inline_schema
    end

    let(:dummy) { double }

    # prevent the mock verify from saying we didn't call the method
    # BECAUSE IT LIES
    after(:each) { RSpec::Mocks.space.proxy_for(dummy).reset }

    context 'when the argument is a hash' do
      let(:inline_schema) { '{"type": "object", "properties": { "name" : { "type" : "string" } } }' }
      let(:valid_hash) { { name: 'bob' } }

      it 'still succeeds' do
        expect(dummy).to receive(:method_call).with(object_matching_schema(:inline_schema))
        dummy.method_call(valid_hash)
      end

      it 'can filter with compound matchers' do
        expect {
          expect(dummy).to receive(:method_call).with(an_instance_of(String).and(object_matching_schema(:inline_schema)))
          dummy.method_call(valid_hash)
        }.to fail_including("unexpected arguments")
      end
    end

    it 'works as an argument matcher' do
      expect(dummy).to receive(:method_call).with(object_matching_schema(:inline_schema))
      dummy.method_call(valid_json)
    end

    it 'does something useful as an argument matcher when it does not match' do
      expect {
        expect(dummy).to receive(:method_call).with(object_matching_schema(:inline_schema))
        dummy.method_call(invalid_json)
      }.to fail_including("The property '#/' of type Hash did not match the following type: string in schema")
    end

    it 'can be used as a deeply nested matcher' do
      expect {
        expect(dummy).to receive(:method_call).with({a: 1, b: 2, c: object_matching_schema(:inline_schema)})
        dummy.method_call(a:1, b:2, c: invalid_json)
      }.to fail_including("The property '#/' of type Hash did not match the following type: string in schema")
    end
  end

  context 'with valid schema_name' do
    before :each do
      RSpec.configuration.json_schemas[:inline_schema] = inline_schema
    end

    specify 'calls JSON::Validator' do
      schema_value = inline_schema
      json_value = valid_json
      validation_options = {strict: true}
      no_errors = []

      expect(JSON::Validator).to receive(:fully_validate) do |schema_value_arg, json_value_arg, validation_options_arg|
        expect(schema_value_arg).to eq(schema_value)
        expect(json_value_arg).to eq(json_value)
        expect(validation_options_arg).to eq(validation_options)
        no_errors
      end

      expect(valid_json).to match_json_schema(:inline_schema, validation_options)
    end

    context 'finds a match' do
      specify 'when tested against valid json' do
        expect(valid_json).to match_json_schema(:inline_schema)
      end

      specify 'assigns a valid description' do
        matcher = match_json_schema(:inline_schema)
        expect(matcher.description).to eq("match JSON schema identified by #{:inline_schema}")
      end
    end

    context 'does not find a match' do
      let(:validator_errors) { [:error1, :error2] }

      specify 'when tested against invalid json' do
        expect(invalid_json).not_to match_json_schema(:inline_schema)
      end

      specify 'assigns a failure message' do
        expect(JSON::Validator).to receive(:fully_validate) { validator_errors.clone }
        matcher = match_json_schema(:inline_schema)
        expect(matcher.matches?(invalid_json)).to eq(false)
        expect(matcher.failure_message).to eq(expected_failure_message)
      end

      def expected_failure_message
        first_failure_message = "Expected JSON object to match schema identified by inline_schema, #{validator_errors.count} errors in validating"
        all_failure_messages = [first_failure_message, *validator_errors]
        all_failure_messages.join("\n")
      end
    end
  end
end
