require 'json-schema-rspec'

# Copyright (c) 2012 David Chelimsky, Myron Marston
# Copyright (c) 2006 David Chelimsky, The RSpec Development Team
# Copyright (c) 2005 Steven Baker
# Shamelessly stolen from rspec-mocks
module RSpec
  module ExpectationFailMatchers
    def fail(&block)
      raise_error(RSpec::Mocks::MockExpectationError, &block)
    end

    def fail_with(*args, &block)
      raise_error(RSpec::Mocks::MockExpectationError, *args, &block)
    end

    def fail_including(*snippets)
      raise_error(
        RSpec::Mocks::MockExpectationError,
        a_string_including(*snippets)
      )
    end
  end
end

Dir[File.expand_path("../../spec/support/**/*.rb",__FILE__)].each { |f| require f }

RSpec.configure do |config|

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_excluding wip: true

  config.include JSON::SchemaMatchers
  config.include RSpec::ExpectationFailMatchers
end
