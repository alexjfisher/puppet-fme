require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
require 'webmock/rspec'

include RspecPuppetFacts

require 'simplecov'
require 'simplecov-console'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console
]

SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
end

RSpec.configure do |config|
  config.mock_with :mocha
end
