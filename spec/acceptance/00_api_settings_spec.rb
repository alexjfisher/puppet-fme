require 'spec_helper_acceptance'

test_fmeserver = ENV['FMESERVER'] || abort('FMESERVER environment variable not set')
describe 'fme::api_settings class' do
  context 'with parameters for test server' do
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { 'fme::api_settings':
        host => '#{test_fmeserver}',
        username => 'admin',
        password => 'admin',
      }
      package {'ruby-rest-client': ensure => 'installed'}
      EOS
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end
  end
end
