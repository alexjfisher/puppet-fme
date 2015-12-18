require 'spec_helper_acceptance'

describe 'fme_resource' do
  before :all do
    pp = <<-EOS
      fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data':
        ensure => absent,
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
    pp = <<-EOS
      fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data':
        ensure => directory,
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
  end
  describe 'files' do
    testfile = '/tmp/testfile'
    before :all do
      create_remote_file(master, testfile, "Test file data")
      apply_manifest("fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile': ensure => absent }", :catch_failures => true)
    end
    describe 'uploading new file' do
      context 'with \'resource\' and \'path\' in resource title' do
        pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure => file,
            source => "#{testfile}",
          }
        EOS
        it 'should work with no errors' do
          apply_manifest(pp, :catch_failures => true)
        end
        it 'should work idempotently' do
          apply_manifest(pp, :catch_changes  => true)
        end
        describe command("curl -H 'Accept: application/octet-stream' --user admin:admin http://#{ENV['FMESERVER']}/fmerest/v2/resources/connections/FME_SHAREDRESOURCE_DATA/filesys/puppet_test_data/testfile") do
          its(:stdout) { should match /Test file data/ }
        end
      end
      context 'with \'resource\' and \'path\' set' do
        pp = <<-EOS
            fme_resource { 'my resource':
              ensure => file,
              resource => 'FME_SHAREDRESOURCE_DATA',
              path   => '/puppet_test_data/testfile',
              source => "#{testfile}",
            }
        EOS
        it 'should work with no errors' do
          apply_manifest(pp, :catch_failures => true)
        end
        it 'should work idempotently' do
          apply_manifest(pp, :catch_changes  => true)
        end
      end
    end
    describe 'size comparisons' do
      context 'when files are same size' do
        it 'should not replace existing file' do
          # Same size, but different content
          create_remote_file(master, '/tmp/file1', "Test file data1")
          create_remote_file(master, '/tmp/file2', "Test file data2")
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure => file,
            source => '/tmp/file1',
          }
          EOS
          apply_manifest(pp, :catch_failures => true)
          apply_manifest(pp, :catch_changes  => true)
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure => file,
            source => '/tmp/file2',
          }
          EOS
          apply_manifest(pp, :catch_changes  => true)
        end
      end
      context 'when files are different sizes' do
        it 'should replace file with new upload' do
          create_remote_file(master, '/tmp/file1', "Test file data1")
          create_remote_file(master, '/tmp/file2', "Bigger test file data2.")
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure => file,
            source => '/tmp/file1',
          }
          EOS
          apply_manifest(pp, :catch_failures => true)
          apply_manifest(pp, :catch_changes  => true)
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure => file,
            source => '/tmp/file2',
          }
          EOS
          apply_manifest(pp, :expect_changes => true)
        end
      end
    end
    describe 'checksumming' do
      context 'when checksum=false' do
        it 'should not replace existing file' do
          # Same size, but different content
          create_remote_file(master, '/tmp/file1', "Test file data1")
          create_remote_file(master, '/tmp/file2', "Test file data2")
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure => file,
            source => '/tmp/file1',
          }
          EOS
          apply_manifest(pp, :catch_failures => true)
          apply_manifest(pp, :catch_changes  => true)
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure   => file,
            source   => '/tmp/file2',
            checksum => false,
          }
          EOS
          apply_manifest(pp, :catch_changes  => true)
        end
      end
      context 'when checksum=true' do
        it 'should replace existing file' do
          # Same size, but different content
          create_remote_file(master, '/tmp/file1', "Test file data1")
          create_remote_file(master, '/tmp/file2', "Test file data2")
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure => file,
            source => '/tmp/file1',
          }
          EOS
          apply_manifest(pp, :catch_failures => true)
          apply_manifest(pp, :catch_changes  => true)
          pp = <<-EOS
          fme_resource { 'FME_SHAREDRESOURCE_DATA:/puppet_test_data/testfile':
            ensure   => file,
            source   => '/tmp/file2',
            checksum => true,
          }
          EOS
          apply_manifest(pp, :expect_changes => true)
        end
      end
    end
  end
end
