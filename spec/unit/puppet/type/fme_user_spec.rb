require 'spec_helper'

describe Puppet::Type.type(:fme_user) do
  describe 'when validating attributes' do
    [ :name, :password, :provider ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
    [ :ensure, :fullname, :roles ].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end
  end
  describe 'namevar validation' do
    it "should have :name as its namevar" do
      expect(described_class.key_attributes).to eq([:name])
    end
  end
  describe 'when validating attribute values' do
    describe 'ensure' do
      [ :present, :absent ].each do |value|
        it "should support #{value} as a value to ensure" do
          expect { described_class.new( {:name => 'example_user', :ensure => value})}.to_not raise_error
        end
      end
      it 'should not support other values' do
        expect { described_class.new( {:name => 'example_user',:ensure => 'foo'})}.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
    describe 'roles' do
      it 'should support single role' do
        expect { described_class.new({:name => 'example_user',:roles => ['foo']})}.to_not raise_error
        expect { described_class.new({:name => 'example_user',:roles => 'foo'})}.to_not raise_error
      end
      it 'should support multiple roles as array of strings' do
        expect { described_class.new({:name => 'example_user',:roles => ['foo','bar']})}.to_not raise_error
      end
      it 'should not support a comma separated list' do
        expect { described_class.new({:name => 'example_user',:roles => 'foo,bar'})}.to raise_error(Puppet::Error, /Roles cannot include ','/)
      end
      it 'should not support a space separated list' do
        expect { described_class.new({:name => 'example_user',:roles => 'foo bar'})}.to raise_error(Puppet::Error, /Roles cannot include ' '/)
      end
      describe 'when testing is in sync' do
        it 'should not care about order' do
          @property = described_class.new(:name => 'example_user', :roles => [ 'foo', 'bar', 'foobar' ]).property(:roles)
          expect(@property).to be_safe_insync([ 'foo', 'bar', 'foobar' ])
          expect(@property).to be_safe_insync([ 'foobar', 'bar', 'foo' ])
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
      @resource = described_class.new(:ensure => :present, :name => 'user', :password => 'secret')
      @catalog.add_resource @resource
      req = @resource.autorequire
      expect(req.size).to eq(1)
      expect(req[0].target).to eq(@resource)
      expect(req[0].source).to eq(@settings_file)
    end
  end
end
