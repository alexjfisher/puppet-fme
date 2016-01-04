require 'spec_helper'

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
    it "should have 3 namevars" do
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
      [ :present, :absent, :file, :directory ].each do |value|
        it "should support #{value} as a value to ensure" do
          expect { described_class.new( {:title => 'RESOURCE:/path', :source => '/path', :ensure => value})}.to_not raise_error
        end
      end
      it 'should not support other values' do
        expect { described_class.new( {:title => 'RESOURCE:/path', :ensure => 'foo'})}.to raise_error(Puppet::Error, /Invalid value/)
      end
      describe ':present is an alias for :file' do
        it 'resource ensure set to :present should equal :file' do
          @resource = described_class.new( {:title => 'RESOURCE:/path', :source => '/path', :ensure => :present })
          expect(@resource[:ensure]).to eq(:file)
        end
      end
      describe 'replacing directories with files' do
        before :each do
          @provider = stub(
            'provider',
            :class => Puppet::Type.type(:fme_resource).defaultprovider,
            :name  => 'rest_client',
            :clear => nil
          )
          Puppet::Type.type(:fme_resource).stubs(:defaultprovider).returns(@provider)
          @resource = Puppet::Type.type(:fme_resource).new( {:title => 'RESOURCE:/path', :ensure => :directory })
        end
        it 'should not be possible' do
          @provider.expects(:properties).returns({:ensure => :directory})
          expect { @resource[:ensure] = :file }.to raise_error(Puppet::Error, /Cannot replace a file with a file!/)
        end
      end
    end

    describe 'checksum' do
      it 'should default to false' do
        resource = described_class.new :title => 'RESOURCE:/path', :ensure => 'file', :path => '/path', :source => '/foo'
        expect(resource[:checksum]).to eq false
      end
    end
  end
end
