require 'spec_helper_acceptance'

describe 'fme_user type' do
  describe 'creating user' do
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      fme_user { 'my_test_user':
        ensure   => present,
        password => 'password',
      }
      EOS
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end
  end
  describe 'delete user' do
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      fme_user { 'my_test_user':
        ensure   => absent,
      }
      EOS
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end
  end
end
describe 'fme_resource' do
  describe 'deleting test directory' do
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data':
        ensure => absent,
      }
      EOS
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end
  end
  describe 'Create test directory' do
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data':
        ensure => directory,
      }
      EOS
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end
  end
  describe 'uploading files' do
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/issue':
        ensure => file,
        source => '/etc/issue',
      }
      EOS
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end
  end
end
