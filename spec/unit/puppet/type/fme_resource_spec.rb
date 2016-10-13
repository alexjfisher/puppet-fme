require 'spec_helper'
require 'digest'
require 'fakefs/spec_helpers'

describe Puppet::Type.type(:fme_resource) do
  before :each do
    Fme::Helper.stubs(:get_url).returns('www.example.com')
  end
  describe 'when validating attributes' do
    [ :name, :provider, :resource, :path, :checksum ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
    [ :ensure ].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end
  end

  describe 'namevars' do
    it 'should have 3 namevars' do
      expect(described_class.key_attributes.size).to eq(3)
    end
    [ :name, :resource, :path ].each do |param|
      it "'#{param}' should be a namevar" do
        expect(described_class.key_attributes).to include(param)
      end
    end
  end

  describe 'when validating attribute values' do
    describe 'ensure' do
      before :each do
        @provider_class = Puppet::Type.type(:fme_resource).provider(:rest_client)
        @provider = stub( 'provider', :class => @provider_class, :clear => nil )
        @provider_class.stubs(:new).returns(@provider)

        Puppet::Type.type(:fme_resource).stubs(:defaultprovider).returns @provider_class

        @resource = Puppet::Type.type(:fme_resource).new({ :title => 'RESOURCE:/path', :ensure => :file, :source => '/path' })
        @property = @resource.property(:ensure)
      end
      [ :present, :absent, :file, :directory ].each do |value|
        it "should support #{value} as a value to ensure" do
          expect { described_class.new( { :title => 'RESOURCE:/path', :source => '/path', :ensure => value })}.to_not raise_error
        end
      end
      it 'should not support other values' do
        expect { described_class.new( { :title => 'RESOURCE:/path', :ensure => 'foo' })}.to raise_error(Puppet::Error, /Invalid value/)
      end
      describe ':present is an alias for :file' do
        it 'resource ensure set to :present should equal :file' do
          @resource = described_class.new( { :title => 'RESOURCE:/path', :source => '/path', :ensure => :present })
          expect(@resource[:ensure]).to eq(:file)
        end
      end
      describe '#sync' do
        context 'should = :file' do
          before :each do
            @property.should = :file
          end
          describe 'when already a file' do
            it 'should destroy then upload file' do
              @provider.expects(:properties).returns({ :ensure => :file, :size => 42 }).twice
              @provider.expects(:destroy)
              @provider.expects(:upload_file)
              @property.sync
            end
          end
          describe 'when currently absent' do
            it 'should upload file' do
              @provider.expects(:properties).returns({ :ensure => :absent })
              @provider.expects(:upload_file)
              @property.sync
            end
          end
          describe 'when currently directory' do
            it 'should raise error' do
              @provider.expects(:properties).returns({ :ensure => :directory })
              expect { @property.sync }.to raise_error(Puppet::Error, /Cannot replace a directory with a file!/)
            end
          end
        end
        context 'should = :directory' do
          before :each do
            @property.should = :directory
          end
          describe 'when currently file' do
            it 'should raise error if trying to replace with file' do
              @provider.expects(:properties).returns({ :ensure => :file })
              expect { @property.sync }.to raise_error(Puppet::Error, /Cannot replace a file with a directory!/)
            end
          end
          describe 'otherwise' do
            it 'should create directory' do
              @provider.expects(:properties).returns({ :ensure => :absent })
              @provider.expects(:create_directory)
              @property.sync
            end
          end
        end
        context 'should = :absent' do
          it 'should call provider.destroy' do
            @property.should = :absent
            @provider.expects(:destroy)
            @property.sync
          end
        end
      end
      describe 'when testing whether :ensure is in sync' do
        it 'should be in sync if :ensure is set to :absent and the provider reports the resource as absent' do
          @property.should = :absent
          expect(@property).to be_safe_insync(:absent)
        end
        it 'should be in sync if :ensure is set to :file and provider reports resource to be a file with matching size' do
          @property.should = :file
          @property.expects(:sizes_match?).returns true
          expect(@property).to be_safe_insync(:file)
        end
        it 'should not be in sync if sizes don\'t match' do
          @property.should = :file
          @property.expects(:sizes_match?).returns false
          expect(@property).not_to be_safe_insync(:file)
        end
        context 'when checksumming enabled' do
          before :each do
            @resource = Puppet::Type.type(:fme_resource).new({ :title => 'RESOURCE:/path', :ensure => :file, :source => '/path', :checksum => true })
            @property = @resource.property(:ensure)
            @property.should = :file
            @property.expects(:sizes_match?).returns true
          end
          it 'should be in sync if checksums match' do
            @property.expects(:checksums_match?).returns true
            expect(@property).to be_safe_insync(:file)
          end
          it 'should no be in sync if checksums don\'t match' do
            @property.expects(:checksums_match?).returns false
            expect(@property).to_not be_safe_insync(:file)
          end
        end
      end
      describe '.sizes_match?' do
        it 'returns true when size_of_source matches size returned by provider' do
          @provider.expects(:properties).returns({ :size => 4242 })
          @property.expects(:size_of_source).returns 4242
          expect(@property.sizes_match?).to eq true
        end
        it 'returns false when size_of_source does not match size returned by provider' do
          @provider.expects(:properties).returns({ :size => 4242 })
          @property.expects(:size_of_source).returns 42
          expect(@property.sizes_match?).to eq false
        end
      end
      describe '.checksums?' do
        it 'returns true when checksum_of_source matches checksum returned by provider' do
          provider_checksum = Digest::SHA256.new
          source_checksum = Digest::SHA256.new
          provider_checksum << 'Matching DATA'
          source_checksum << 'Matching DATA'
          @provider.expects(:checksum).returns provider_checksum
          @property.expects(:checksum_of_source).returns source_checksum
          expect(@property.checksums_match?).to eq true
        end
        it 'returns false when checksum_of_source does not match checksum returned by provider' do
          provider_checksum = Digest::SHA256.new
          source_checksum = Digest::SHA256.new
          provider_checksum << 'Non-Matching DATA'
          source_checksum << "DATA that doesn't match"
          @provider.expects(:checksum).returns provider_checksum
          @property.expects(:checksum_of_source).returns source_checksum
          expect(@property.checksums_match?).to eq false
        end
      end
      describe '.change_to_s' do
        it 'returns "uploaded new file" when creating a new file' do
          expect(@property.change_to_s(:absent, :file)).to eq 'uploaded new file'
        end
        it 'returns "created directory" when creating a new directory' do
          expect(@property.change_to_s(:absent, :directory)).to eq 'created directory'
        end
        it 'returns "deleted file" when deleting a file' do
          expect(@property.change_to_s(:file, :absent)).to eq 'deleted file'
        end
        it 'returns "deleted directory" when deleting a directory' do
          expect(@property.change_to_s(:directory, :absent)).to eq 'deleted directory'
        end
        it 'returns "replaced file of size..." when replacing a file' do
          @property.expects(:size_of_source).returns 42
          expect(@property.change_to_s(:file, :file)).to match /replaced file of size  bytes with one of 42 bytes/
        end
      end
      describe '.size_of_source' do
        it 'returns file size of source file' do
          File.expects(:size?).returns 10
          expect(@property.size_of_source).to eq 10
        end
      end
      describe '.checksum_of_source' do
        include FakeFS::SpecHelpers
        it 'returns the checksum of the source file' do
          mock_source_file = '/path'
          File.open(mock_source_file, 'w') do |f|
            f.write 'DATA'
          end
          #echo -n "DATA" | sha256sum -
          #c97c29c7a71b392b437ee03fd17f09bb10b75e879466fc0eb757b2c4a78ac938
          expect(@property.checksum_of_source.hexdigest).to eq 'c97c29c7a71b392b437ee03fd17f09bb10b75e879466fc0eb757b2c4a78ac938'
        end
      end
    end

    describe 'checksum' do
      it 'should default to false' do
        resource = described_class.new :title => 'RESOURCE:/path', :ensure => 'file', :path => '/path', :source => '/foo'
        expect(resource[:checksum]).to eq false
      end
    end

    describe 'source' do
      it 'should fail if not an absolute path' do
        expect { described_class.new( { :title => 'RESOURCE:/path', :source => 'not_absolute', :ensure => :file })}.to raise_error(Puppet::Error, /'source' file path must be absolute, not 'not_absolute'/)
      end
    end
  end
end
