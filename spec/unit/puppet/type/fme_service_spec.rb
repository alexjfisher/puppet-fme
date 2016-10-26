require 'spec_helper'

describe Puppet::Type.type(:fme_service) do
  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
    [:ensure, :display_name, :url, :description].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end
  end
  describe 'namevar validation' do
    it 'should have :name as its namevar' do
      expect(described_class.key_attributes).to eq([:name])
    end
  end
  describe 'when validating attribute values' do
    describe 'ensure' do
      before :each do
        @provider_class = Puppet::Type.type(:fme_service).provider(:rest_client)
        @provider = stub('provider', :class => @provider_class, :clear => nil)
        @provider_class.stubs(:new).returns(@provider)

        Puppet::Type.type(:fme_service).stubs(:defaultprovider).returns @provider_class

        @resource = Puppet::Type.type(:fme_service).new(:title => 'service', :ensure => :present)
        @property = @resource.property(:ensure)
      end
      [:present, :absent].each do |value|
        it "should support #{value} as a value to ensure" do
          expect { described_class.new(:name => 'example_service', :ensure => value) }.to_not raise_error
        end
      end
      it 'should not support other values' do
        expect { described_class.new(:name => 'example_service', :ensure => 'foo') }.to raise_error(Puppet::Error, %r{Invalid value})
      end
      describe 'Creating and deleting services' do
        it 'does not support deleting fme_services' do
          @property.should = :absent
          expect { @property.sync }.to raise_error(Puppet::Error, %r{Deletion of fme_service resources not implemented})
        end
        it 'does not support creating fme_services' do
          @property.should = :present
          expect { @property.sync }.to raise_error(Puppet::Error, %r{Creation of fme_service resources not implemented})
        end
      end
    end
  end

  describe 'autorequiring' do
    before :each do
      @settings_file = Puppet::Type.type(:file).new(:name => '/etc/fme_api_settings.yaml', :ensure => :file)
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @settings_file
    end

    it 'should autorequire the settings file' do
      @resource = described_class.new(:ensure => :present, :name => 'example_service', :description => 'new description')
      @catalog.add_resource @resource
      req = @resource.autorequire
      expect(req.size).to eq(1)
      expect(req[0].target).to eq(@resource)
      expect(req[0].source).to eq(@settings_file)
    end
  end
end
