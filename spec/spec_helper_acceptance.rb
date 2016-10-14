require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker_spec_helper'
include BeakerSpecHelper

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'

RSpec.configure do |c|
  # Project root
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => module_root, :module_name => 'fme')
    hosts.each do |host|
      on host, puppet('apply -e "package { \'git\': ensure => installed }"')
      BeakerSpecHelper.spec_prep(host)
    end
  end
end
