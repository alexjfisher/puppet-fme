require 'spec_helper'
require 'digest'
require 'fakefs/spec_helpers'

describe Puppet::Type.type(:fme_repository_item) do
  before :each do
    Fme::Helper.stubs(:get_url).returns('www.example.com')
  end
  describe 'when validating attributes' do
    [ :name, :provider, :repository, :item, :source ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
    [ :ensure, :description, :item_title, :type, :last_save_date, :services ].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end
  end

  describe 'namevars' do
    it 'should have 3 namevars' do
      expect(described_class.key_attributes.size).to eq(3)
    end
    [ :name, :repository, :item ].each do |param|
      it "'#{param}' should be a namevar" do
        expect(described_class.key_attributes).to include(param)
      end
    end
  end

  describe 'when validating attribute values' do
    describe 'ensure' do
      before :each do
        @provider_class = Puppet::Type.type(:fme_repository_item).provider(:rest_client)
        @provider = stub( 'provider', :class => @provider_class, :clear => nil )
        @provider_class.stubs(:new).returns(@provider)

        Puppet::Type.type(:fme_repository_item).stubs(:defaultprovider).returns @provider_class

        @resource = Puppet::Type.type(:fme_repository_item).new({:title => 'repo:/item.fmw', :ensure => :present, :source => '/path/to/item.fmw' })
        @property = @resource.property(:ensure)
      end
      [ :present, :absent ].each do |value|
        it "should support #{value} as a value to ensure" do
          expect { described_class.new( {:title => 'repo/item.fmw', :source => '/path/to/item.fmw', :ensure => value})}.to_not raise_error
        end
      end
      it 'should not support other values' do
        expect { described_class.new( {:title => 'repo/item.fmw',:ensure => 'foo'})}.to raise_error(Puppet::Error, /Invalid value/)
      end
      describe '#sync' do
        context 'should = :present' do
          before :each do
            @property.should = :present
          end
          describe 'when already exists' do
            it 'should remove then reupload workspace' do
              @provider.expects(:exists?).returns(true)
              @provider.expects(:destroy)
              @provider.expects(:create)
              @property.sync
            end
          end
          describe 'when it doesn\'t exist' do
            it 'should upload workspace' do
              @provider.expects(:exists?).returns(false)
              @provider.expects(:destroy).never
              @provider.expects(:create)
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
        it 'should be in sync if :ensure is set to :absent and the provider rep  orts the resource as absent' do
          @property.should = :absent
          expect(@property).to be_safe_insync(:absent)
        end
        it 'should be in sync if :ensure is set to :present and provider reports resource present and matching' do
          @property.should = :present
          @property.expects(:items_match?).returns true
          expect(@property).to be_safe_insync(:present)
        end
        it 'should not be insync if items don\'t match' do
          @property.should = :present
          @property.expects(:items_match?).returns false
          expect(@property).not_to be_safe_insync(:present)
        end
      end
      describe '.items_match?' do
        it 'returns true when checksums match' do
          data = 'Matching DATA'
          provider_checksum = Digest::SHA256.new
          source_checksum = Digest::SHA256.new
          provider_checksum << data
          source_checksum   << data
          @provider.expects(:checksum).returns provider_checksum
          @property.expects(:checksum_of_source).returns source_checksum
          expect(@property.items_match?).to eq true
        end
        it 'returns false when checksums don\'t match' do
          provider_checksum = Digest::SHA256.new
          source_checksum = Digest::SHA256.new
          provider_checksum << 'DATA'
          source_checksum   << 'Non-matching DATA'
          @provider.expects(:checksum).returns provider_checksum
          @property.expects(:checksum_of_source).returns source_checksum
          expect(@property.items_match?).to eq false
        end
      end
    describe '.checksum_of_source' do
        include FakeFS::SpecHelpers
        it 'returns the checksum of the source file' do
          mock_source_file = '/path/to/item.fmw'
          FileUtils.mkdir_p '/path/to'
          File.open(mock_source_file,'w') do |f|
            f.write 'DATA'
          end
          #echo -n "DATA" | sha256sum -
          #c97c29c7a71b392b437ee03fd17f09bb10b75e879466fc0eb757b2c4a78ac938
          expect(@property.checksum_of_source.hexdigest).to eq 'c97c29c7a71b392b437ee03fd17f09bb10b75e879466fc0eb757b2c4a78ac938'
        end
      end
    end

    describe 'name' do
      context 'when not set' do
        it 'should be munged to <repository>/<item>' do
          expect { @item = described_class.new( {:title => 'resourcetitle', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present})}.to_not raise_error
          expect(@item[:name]).to eq('repo/item.fmw')
        end
      end
      context 'when set' do
        context 'to match <repository>/<item>' do
          it 'should be unaffected by munge' do
            expect { @item = described_class.new( {:title => 'resourcetitle', :name => 'repo/item.fmw', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present})}.to_not raise_error
            expect(@item[:name]).to eq('repo/item.fmw')
          end
        end
        context 'with mismatched repository or item' do
          it 'should raise error' do
            expect { @item = described_class.new( {:title => 'resourcetitle', :name => 'repo2/item42.fmw', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present})}.to raise_error(Puppet::Error, /'name' should not be used/)
          end
        end
      end
    end

    describe 'services' do
      it 'should support a single service' do
        expect { described_class.new({:title => 'repo/item.fmw', :ensure => 'present', :source => '/path/to/item.fmw', :services => ['service1']})}.to_not raise_error
        expect { described_class.new({:title => 'repo/item.fmw', :ensure => 'present', :source => '/path/to/item.fmw', :services => 'service1'})}.to_not raise_error
      end
      it 'should support multiple services as array of strings' do
        expect { described_class.new({:title => 'repo/item.fmw', :ensure => 'present', :source => '/path/to/item.fmw', :services => ['service1','service2']})}.to_not raise_error
      end
      it 'should not support a comma separated list' do
        expect { described_class.new({:title => 'repo/item.fmw', :ensure => 'present', :source => '/path/to/item.fmw', :services => 'service1,service2'})}.
          to raise_error(Puppet::Error, /Services cannot include ','/)
      end
      it 'should not support a space separated list' do
        expect { described_class.new({:title => 'repo/item.fmw', :ensure => 'present', :source => '/path/to/item.fmw', :services => 'service1 service2'})}.
          to raise_error(Puppet::Error, /Services cannot include ' '/)
      end
      describe 'when testing is in sync' do
        it 'should not care about order' do
          @property = described_class.new(:title => 'repo/item.fmw', :ensure => 'present', :source => '/path/to/item.fmw', :services => ['s1','s2','s3']).property(:services)
          expect(@property).to be_safe_insync([ 's1', 's2', 's3' ])
          expect(@property).to be_safe_insync([ 's2', 's1', 's3' ])
          expect(@property).to be_safe_insync([ 's3', 's1', 's2' ])
          expect(@property).to be_safe_insync([ 's3', 's2', 's1' ])
        end
      end
    end

    describe 'read-only properties' do
      before :each do
        @item = Puppet::Type.type(:fme_repository_item).new( {:title => 'repo/item.fmw', :ensure => 'present', :source => '/path/to/item.fmw'} )
      end
      [ :description, :item_title, :type, :last_save_date ].each do |param|
        describe param do
          it 'should raise error' do
            expect { @item[param] = 'foo' }.to raise_error(Puppet::Error, /#{param} is read-only/)
          end
        end
      end
    end
  end

  describe 'autorequiring' do
    before :each do
      @settings_file = Puppet::Type.type(:file).new(:name => '/etc/fme_api_settings.yaml', :ensure => :file)
      @repository    = Puppet::Type.type(:fme_repository).new(:name => 'repo', :ensure => :present)
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @settings_file
      @catalog.add_resource @repository
    end

    it 'should autorequire the settings file' do
      @resource = described_class.new(:title => 'resourcetitle', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present)
      @catalog.add_resource @resource
      req = @resource.autorequire
      expect(req.find {|relationship| relationship.source == @settings_file and relationship.target == @resource}).to_not be_nil
    end

    it 'should autorequire its repository' do
      @resource = described_class.new(:title => 'resourcetitle', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present)
      @catalog.add_resource @resource
      req = @resource.autorequire
      expect(req.find {|relationship| relationship.source == @repository and relationship.target == @resource}).to_not be_nil
    end
  end
end
