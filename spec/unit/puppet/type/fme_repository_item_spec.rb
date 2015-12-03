require 'spec_helper'

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
    [ :ensure, :description, :item_title, :type, :last_save_date ].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end
  end

  describe 'namevars' do
    it "should have 3 namevars" do
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
      [ :present, :absent ].each do |value|
        it "should support #{value} as a value to ensure" do
          expect { described_class.new( {:title => 'repo/item.fmw', :source => '/path/to/item.fmw', :ensure => value})}.to_not raise_error
        end
      end
      it 'should not support other values' do
        expect { described_class.new( {:title => 'repo/item.fmw',:ensure => 'foo'})}.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'name' do
      context "when not set" do
        it 'should be munged to <repository>/<item>' do
          expect { @item = described_class.new( {:title => 'resourcetitle', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present})}.to_not raise_error
          expect(@item[:name]).to eq('repo/item.fmw')
        end
      end
      context "when set" do
        context "to match <repository>/<item>" do
          it 'should raise error' do
            expect { @item = described_class.new( {:title => 'resourcetitle', :name => 'repo/item.fmw', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present})}.to_not raise_error
          end
        end
        context "with mismatched repository or item" do
          it 'should raise error' do
            expect { @item = described_class.new( {:title => 'resourcetitle', :name => 'repo2/item42.fmw', :repository => 'repo', :item => 'item.fmw', :source => '/path/to/item.fmw', :ensure => :present})}.to raise_error(Puppet::Error, /'name' should not be used/)
          end
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
