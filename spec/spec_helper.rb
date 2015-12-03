require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
require 'webmock/rspec'

include RspecPuppetFacts

require 'simplecov'
require 'simplecov-console'
require 'coveralls'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
end

RSpec.configure do |config|
  config.mock_with :mocha
end
