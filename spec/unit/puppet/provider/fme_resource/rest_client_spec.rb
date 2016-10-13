require 'spec_helper'
require 'fakefs/spec_helpers'
require 'digest'

provider_class = Puppet::Type.type(:fme_resource).provider(:rest_client)
describe provider_class do
  before :each do
    Fme::Helper.stubs(:get_url).returns('www.example.com')
  end

  let :resource do
    Puppet::Type.type(:fme_resource).new(:title => 'FME_SHAREDRESOURCE_DATA:/path/to/resource', :provider => :rest_client)
  end

  let :provider do
    resource.provider
  end

  describe '#get_file_metadata' do
    context 'when response code is 200' do
      before :each do
        stub_request(:get, 'http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource?depth=0&detail=low').
          to_return(:status => 200, :body => { 'a' => 1, 'b' => 2 }.to_json)
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
        stub_request(:get, 'http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource?depth=0&detail=low').
          to_return(:status => 404)
      end
      it 'should return nil' do
        expect(provider.get_file_metadata('FME_SHAREDRESOURCE_DATA','/path/to/resource')).to be_nil
      end
    end
    context 'when response code is 403' do
      before :each do
        stub_request(:get, 'http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource?depth=0&detail=low').
          to_return(:status => 403, :body => { 'response' => 'hash' }.to_json)
      end
      it 'should raise exception' do
        expect{provider.get_file_metadata('FME_SHAREDRESOURCE_DATA','/path/to/resource')}.
          to raise_error(Puppet::Error,
                         /FME Rest API returned 403 when getting metadata for FME_SHAREDRESOURCE_DATA:\/path\/to\/resource\. {"response"=>"hash"}/)
      end
    end
  end

  describe '#checksum' do
    context 'when API success' do
      it 'should return checksum of data' do
        mock_data = 'DATA'
        expected_checksum = Digest::SHA256.new
        expected_checksum << mock_data

        stub_request(:get, 'http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys/path/to/resource').
          to_return(:status => 200, :body => mock_data)

        checksum = provider.checksum
        expect(checksum).to eq expected_checksum
      end
    end
    context 'on API failure' do
      it 'should raise error' do
        stub_request(:get, 'http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys/path/to/resource').
          to_return(:status => 404)
        expect{provider.checksum}.
          to raise_error(Puppet::Error, /Error calculating checksum 404/)
      end
    end
  end

  describe '#extract_metadata_from_response' do
    context 'when response is for a file' do
      metadata = nil
      before :each do
        response = { 'type' => 'FILE', 'path' => '/foo/bar/', 'name' => 'testfile', 'size' => 42 }
        metadata = provider.extract_metadata_from_response(response)
      end
      it 'should return a hash' do
        expect(metadata).to be_kind_of(Hash)
      end
      it 'should set :ensure => :file' do
        expect(metadata[:ensure]).to eq :file
      end
      it 'should set :path correctly' do
        expect(metadata[:path]).to eq '/foo/bar/testfile'
      end
      it 'should set :size correctly' do
        expect(metadata[:size]).to eq 42
      end
    end
    context 'when response is for a directory' do
      metadata = nil
      before :each do
        response = { 'type' => 'DIR', 'path' => '/foo/bar/', 'name' => 'foobar', 'size' => 0 }
        metadata = provider.extract_metadata_from_response(response)
      end
      it 'should return a hash' do
        expect(metadata).to be_kind_of(Hash)
      end
      it 'should set :ensure => :directory' do
        expect(metadata[:ensure]).to eq :directory
      end
      it 'should set :path correctly' do
        expect(metadata[:path]).to eq '/foo/bar/foobar'
      end
      it 'should not set :size' do
        expect(metadata[:size]).to be_nil
      end
    end
  end

  describe '#upload_file' do
    describe 'validation' do
      it 'should call validate_source' do
        provider.expects(:validate_source)
        provider.stubs(:read_source).returns('DATA')
        RestClient.stubs(:post)
        provider.upload_file
      end
    end
    describe 'API post' do
      before :each do
        provider.stubs(:validate_source)
        provider.stubs(:read_source).returns('DATA')
        provider.stubs(:get_post_url).returns('http://URL')
        provider.stubs(:post_params_for_upload_file).returns({ 'post' => 'params' })
      end
      context 'when successful' do
        it 'should not raise any error' do
          stub_request(:post, 'http://url/').
            with(:body => 'DATA', :headers => { 'Post'=>'params' }).
            to_return(:status => 201, :body => '')
          expect{provider.upload_file}.to_not raise_error
        end
      end
      context 'when unsuccessful' do
        it 'should raise error' do
          stub_request(:post, 'http://url/').
            with(:body => 'DATA', :headers => { 'Post'=>'params' }).
            to_return(:status => 409, :body => '{"what": "/for/bar/upload", "reason": "exists", "message": "File \'upload\' already exists"}')
          expect{provider.upload_file}.to raise_error(Puppet::Error, /FME Rest API returned 409 when uploading FME_SHAREDRESOURCE_DATA:\/path\/to\/resource\. {"what"=>"\/for\/bar\/upload", "reason"=>"exists", "message"=>"File 'upload' already exists"/)
        end
      end
    end
  end
  describe '#create_directory' do
    before :each do
      provider.stubs(:get_post_url).returns('http://URL')
    end
    context 'when successful' do
      it 'should not raise any error' do
        stub_request(:post, 'http://url/').
          with(:body => 'directoryname=resource&type=DIR').
          to_return(:status => 201)
        expect{provider.create_directory}.to_not raise_error
      end
    end
    context 'when unsuccessful' do
      it 'should raise error' do
        stub_request(:post, 'http://url/').
          with(:body => 'directoryname=resource&type=DIR').
          to_return(:status => 409, :body => '{"what": "/for/bar/testdir", "reason": "exists", "message": "Directory \'testdir\' already exists"}')
        expect{provider.create_directory}.to raise_error(Puppet::Error, /FME Rest API returned 409 when creating directory FME_SHAREDRESOURCE_DATA:\/path\/to\/resource\. {"what"=>"\/for\/bar\/testdir", "reason"=>"exists", "message"=>"Directory 'testdir' already exists"/)
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
    it 'should return data from source file' do
      mock_source_file = '/testfile'
      resource[:source] = mock_source_file
      mock_data = 'DATA'
      FakeFS do
        File.open(mock_source_file,'w') do |f|
          f.write mock_data
        end
        expect(provider.read_source).to eq mock_data
      end
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
      stub_request(:delete, 'http://www.example.com/resources/connections/FME_SHAREDRESOURCE_DATA/filesys//path/to/resource')
    end
    it 'should delete the resource' do
      provider.destroy
    end
    it 'should clear the property hash' do
      provider.instance_variable_set(:@property_hash,{ :ensure => :file })
      expect(provider.instance_variable_get(:@property_hash)).to eq :ensure => :file
      provider.destroy
      expect(provider.instance_variable_get(:@property_hash)).to be_empty
    end
  end

  describe '#properties' do
    context 'when property hash is empty' do
      before :each do
        provider.instance_variable_set(:@property_hash,{})
      end
      context 'when resource is found' do
        it 'should return result of get_file_metadata' do
          provider.expects(:get_file_metadata).returns({ :ensure => :file })
          expect(provider.properties).to eq({ :ensure => :file })
        end
      end
      context 'when resource is not found' do
        it 'should set :ensure => :absent' do
          provider.expects(:get_file_metadata).returns nil
          expect(provider.properties).to eq({ :ensure => :absent })
        end
      end
    end
  end
end
