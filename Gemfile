source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  gem "rake"
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "rspec", '< 3.2.0'
  gem "rspec-puppet"
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "rspec-puppet-facts"
  gem 'simplecov', '>= 0.9.0'
  gem 'simplecov-console'
  gem 'coveralls', :require => false

  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem "puppet-lint-unquoted_string-check"

  gem "rest-client"
  gem "webmock", '< 2.0'
  gem "mocha"
  gem "fakefs"

  if RUBY_VERSION < '2.0'
    gem 'json',           '~> 1.8'
    gem 'json_pure',      '= 2.0.1'
    gem 'addressable',    '= 2.3.8'
    gem 'tins',           '= 1.6.0'
    gem 'term-ansicolor', '< 1.4.0'
  else
    gem 'json'
    gem 'tins'
    gem 'rubocop', '0.43.0'
  end
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "puppet-blacksmith"
  gem "guard-rake"
end

group :system_tests do
  gem "beaker"
  gem "beaker-rspec"
  gem "beaker-puppet_install_helper"
  gem "beaker_spec_helper"
end
