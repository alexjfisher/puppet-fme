require 'spec_helper'
require 'fakefs/spec_helpers'

provider_class = Puppet::Type.type(:fme_resource).provider(:rest_client)
describe provider_class do
  before :each do
    Fme::Helper.stubs(:get_url).returns('www.example.com')
  end

  let :resource do
    Puppet::Type.type(:fme_resource).new(:title => "FME_SHAREDRESOURCE_DATA:/path/to/resource", :provider => :rest_client)
  end

  let :provider do
    resource.provider
  end

  describe '#get_file_metadata' do
    context 'when response code is 200' do
      before :each do
        stub_request(:get, "http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource?depth=0&detail=low").
          to_return(:status => 200, :body => {'a' => 1, 'b' => 2}.to_json)
      end
      it 'should call extract_metadata_from_response with hash parsed from json response' do
        provider.expects(:extract_metadata_from_response).with('a' => 1, 'b' => 2)
        provider.get_file_metadata('FME_SHAREDRESOURCE_DATA','/path/to/resource')
      end
      it 'should return result of extract_metadata_from_response' do
        mock_hash = { 'mock' => 'hash' }
        provider.expects(:extract_metadata_from_response).returns mock_hash
        expect(provider.get_file_metadata('FME_SHAREDRESOURCE_DATA','/path/to/resource')).to eq mock_hash
      end
    end
    context 'when response code is 404' do
      before :each do
        stub_request(:get, "http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource?depth=0&detail=low").
          to_return(:status => 404)
      end
      it 'should return empty hash' do
        expect(provider.get_file_metadata('FME_SHAREDRESOURCE_DATA','/path/to/resource')).to be_kind_of(Hash)
        expect(provider.get_file_metadata('FME_SHAREDRESOURCE_DATA','/path/to/resource')).to be_empty
      end
    end
    context 'when response code is 403' do
      before :each do
        stub_request(:get, "http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource?depth=0&detail=low").
          to_return(:status => 403, :body => {'response' => 'hash'}.to_json)
      end
      it 'should raise exception' do
        #FME Rest API returned #{response.code} when getting metadata for #{resource[:name]}. #{JSON.parse(response)}
        expect{provider.get_file_metadata('FME_SHAREDRESOURCE_DATA','/path/to/resource')}.
          to raise_error(Puppet::Error,
                         /FME Rest API returned 403 when getting metadata for FME_SHAREDRESOURCE_DATA:\/path\/to\/resource\. {"response"=>"hash"}/)
      end
    end
  end

  describe '#has_source?' do
    context 'when source parameter has been specified' do
      it 'should return true' do
        resource[:source] = '/path/to/file'
        expect(provider.has_source?).to eq true
      end
    end
    context 'when no source parameter' do
      it 'should return false' do
        expect(provider.has_source?).to eq false
      end
    end
  end

  describe '#read_source' do
    include FakeFS::SpecHelpers
    it 'should return data from source file' do
      mock_source_file = '/testfile'
      mock_data = 'DATA'
      File.open(mock_source_file,'w') do |f|
        f.write mock_data
      end
      resource[:source] = mock_source_file
      expect(provider.read_source).to eq mock_data
    end
  end

  describe '#validate_source' do
    context 'when has_source?' do
      it 'should do nothing' do
        provider.expects(:has_source?).returns(true)
        expect{provider.validate_source}.to_not raise_error
      end
    end
    context 'when has_source? is false' do
      it 'should raise an exception' do
        provider.expects(:has_source?).returns(false)
        expect{provider.validate_source}.to raise_error(Puppet::Error, /source is required when creating new resource file/)
      end
    end
  end

  describe '#destroy' do
    before :each do
      stub_request(:delete, "http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource")
    end
    it 'should delete the resource' do
      provider.destroy
    end
    it 'should clear the property hash' do
      provider.instance_variable_set(:@property_hash,{:ensure => :file})
      expect(provider.instance_variable_get(:@property_hash)).to eq :ensure => :file
      provider.destroy
      expect(provider.instance_variable_get(:@property_hash)).to be_empty
    end
  end
end
