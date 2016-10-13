require 'spec_helper'

provider_class = Puppet::Type.type(:fme_repository_item).provider(:rest_client)

describe provider_class do
  before :each do
    Fme::Helper.stubs(:get_url).returns('www.example.com')
  end

  describe 'instances' do
    it 'should have an instances method' do
      expect(described_class).to respond_to :instances
    end

    describe 'returns correct instances' do
      context 'when there are no repositories' do
        before :each do
          stub_request(:get, 'http://www.example.com/repositories?detail=high').to_return(:body => [].to_json)
        end
        it 'should return no resources' do
          expect(described_class.instances.size).to eq(0)
        end
      end
      context 'when there is 1 repository with no items' do
        before :each do
          stub_request(:get, 'http://www.example.com/repositories?detail=high').
            to_return(:body => [{ 'name'=>'repo1', 'description'=>'empty repo' }].to_json)
          stub_request(:get, 'http://www.example.com/repositories/repo1/items?detail=high').to_return(:body => [].to_json)
        end
        it 'should return no resources' do
          expect(described_class.instances.size).to eq(0)
        end
      end
      context 'when there are 2 repositories with 2 items' do
        before :each do
          stub_request(:get, 'http://www.example.com/repositories?detail=high').
            to_return(:body =>
                      [
                        { 'name'=>'repo1', 'description'=>'test repo1' },
                        { 'name'=>'repo2', 'description'=>'test repo2' }
                      ].to_json)
            stub_request(:get, 'http://www.example.com/repositories/repo1/items?detail=high').
              to_return(:body =>
                        [
                          { 'name'=>'item1.fmw', 'description' => 'item1 description', 'title' => 'title1', 'type' => 'WORKSPACE', 'lastSaveDate' => '2014-12-11T11:36:12' },
                          { 'name'=>'item2.fmw', 'description' => 'item2 description', 'title' => 'title2', 'type' => 'WORKSPACE', 'lastSaveDate' => '2014-12-11T11:36:13' }
                        ].to_json)
              stub_request(:get, 'http://www.example.com/repositories/repo2/items?detail=high').
                to_return(:body =>
                          [
                            { 'name'=>'item3.fmw', 'description' => 'item3 description', 'title' => 'title3', 'type' => 'WORKSPACE', 'lastSaveDate' => '2014-12-11T11:36:14' },
                            { 'name'=>'item4.fmw', 'description' => 'item4 description', 'title' => 'title4', 'type' => 'WORKSPACE', 'lastSaveDate' => '2014-12-11T11:36:15' }
                          ].to_json)
        end

        it 'should return 4 resources' do
          expect(described_class.instances.size).to eq(4)
        end

        it 'should return the resource repo1/item1.fmw' do
          expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq( {
            :ensure         => :present,
            :provider       => :rest_client,
            :name           => 'repo1/item1.fmw',
            :description    => 'item1 description',
            :repository     => 'repo1',
            :item           => 'item1.fmw',
            :type           => 'WORKSPACE',
            :last_save_date => '2014-12-11T11:36:12',
            :item_title     => 'title1'
          } )
        end

        it 'should return the resource repo1/item2.fmw' do
          expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq( {
            :ensure         => :present,
            :provider       => :rest_client,
            :name           => 'repo1/item2.fmw',
            :description    => 'item2 description',
            :repository     => 'repo1',
            :item           => 'item2.fmw',
            :type           => 'WORKSPACE',
            :last_save_date => '2014-12-11T11:36:13',
            :item_title     => 'title2'
          } )
        end

        it 'should return the resource repo2/item3.fmw' do
          expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq( {
            :ensure         => :present,
            :provider       => :rest_client,
            :name           => 'repo2/item3.fmw',
            :description    => 'item3 description',
            :repository     => 'repo2',
            :item           => 'item3.fmw',
            :type           => 'WORKSPACE',
            :last_save_date => '2014-12-11T11:36:14',
            :item_title     => 'title3'
          } )
        end

        it 'should return the resource repo2/item4.fmw' do
          expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq( {
            :ensure         => :present,
            :provider       => :rest_client,
            :name           => 'repo2/item4.fmw',
            :description    => 'item4 description',
            :repository     => 'repo2',
            :item           => 'item4.fmw',
            :type           => 'WORKSPACE',
            :last_save_date => '2014-12-11T11:36:15',
            :item_title     => 'title4'
          } )
        end
      end
    end
  end

  describe 'prefetch' do
    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'when an instance' do
    let(:title) { 'repo/item.fmw' }
    let(:resource) do
      Puppet::Type.type(:fme_repository_item).new(
        :title    => title,
        :source   => '/path/to/item.fmw',
        :ensure   => :present,
        :provider => :rest_client
      )
    end

    let(:provider) do
      provider = provider_class.new
      provider.resource = resource
      provider
    end

    describe 'is being checked for existence' do
      it 'should indicate when the fme_repository_item already exists' do
        provider = provider_class.new(:ensure => :present)
        expect(provider.exists?).to be_truthy
      end
      it 'should indicate when the fme_repository_item does not exist' do
        provider = provider_class.new(:ensure => :absent)
        expect(provider.exists?).to be_falsey
      end
    end

    describe 'is being created' do
      before :each do
        provider.stubs(:read_item_from_file).returns('FILEDATA')
      end
      it 'should have a create method' do
        expect(provider).to respond_to(:create)
      end
      context 'when API returns success' do
        before :each do
          stub_request(:post, 'http://www.example.com/repositories/repo/items').
            with(:body => 'FILEDATA',
                 :headers => { 'Accept'=>'application/json', 'Content-Disposition'=>'attachment; filename="item.fmw"', 'Content-Type'=>'application/octet-stream', 'Detail'=>'low', 'Multipart'=>'true', 'Repository'=>'repo' }).
            to_return(:status => 201, :body => { 'name'=>'test.fmw', 'description' => 'a description', 'title' => 'a title', 'type' => 'WORKSPACE', 'lastSaveDate' => '2014-12-11T11:32:50' }.to_json)
        end
        it 'should create a repository_item' do
          provider.create
          expect(provider.instance_variable_get('@property_hash')).to eq( {
            :ensure         => :present,
            :provider       => :rest_client,
            :name           => 'repo/test.fmw',
            :repository     => 'repo',
            :item           => 'test.fmw',
            :item_title     => 'a title',
            :type           => 'WORKSPACE',
            :last_save_date => '2014-12-11T11:32:50',
            :description    => 'a description'
          } )
        end
      end
      context 'when API returns an error' do
        before :each do
          stub_request(:post, 'http://www.example.com/repositories/repo/items').
            with(:body => 'FILEDATA',
                 :headers => { 'Accept'=>'application/json', 'Content-Disposition'=>'attachment; filename="item.fmw"', 'Content-Type'=>'application/octet-stream', 'Detail'=>'low', 'Multipart'=>'true', 'Repository'=>'repo' }).
            to_return(:status => 409, :body => { 'what'=>'test.fmw', 'reason' => 'exists', 'message' => "File 'test.fmw' already exists" }.to_json)
        end
        it 'should raise an exception' do
          expect{ provider.create }.to raise_error(Puppet::Error, /FME Rest API returned 409 when creating repo\/item\.fmw/)
        end
      end
    end
    describe 'is being destroyed' do
      before :each do
        stub_request(:delete, 'http://www.example.com/repositories/repo/items/item.fmw').
          to_return(:status => 200)
      end
      it 'should have @property_hash cleared' do
        provider.destroy
        expect(provider.instance_variable_get('@property_hash')).to be_empty
      end
    end
    describe 'read_item_from_file' do
      before :each do
        File.expects(:new).with('/path/to/item.fmw').returns('DATA')
      end
      it 'should return data from a file' do
        expect(provider.read_item_from_file).to eq('DATA')
      end
    end
    describe 'is managing services' do
      describe '.services' do
        context 'when item has no services' do
          before :each do
            stub_request(:get, 'http://www.example.com/repositories/repo/items/item.fmw/services').
              with(:headers => { 'Accept'=>'application/json' } ).
              to_return(:status => 200, :body => [].to_json)
          end
          it 'should return names of the services' do
            expect(provider.services).to eq([])
          end
        end

        context 'when item has 2 services' do
          before :each do
            stub_request(:get, 'http://www.example.com/repositories/repo/items/item.fmw/services').
              with(:headers => { 'Accept'=>'application/json' } ).
              to_return(
                :status => 200,
                :body   => [
                  { 'displayName' => 'service name 1', 'name' => 'service1' },
                  { 'displayName' => 'service name 2', 'name' => 'service2' }
                ].to_json
              )
          end
          it 'should return 2 services' do
            expect(provider.services.size).to eq(2)
            expect(provider.services[0]).to eq('service1')
            expect(provider.services[1]).to eq('service2')
            expect(provider.services).to eq(['service1','service2'])
          end
        end
      end

      describe '.services=' do
        it 'should process PUT responses with process_put_services_response' do
          stub_request(:put, 'http://www.example.com/repositories/repo/items/item.fmw/services').
            with(:body => { 'services'=>'service2' }).
            to_return(:status => 200,
                      :body => 'dummy_response')
            provider.expects(:process_put_services_response).with(['service1','service2'],'dummy_response')
            provider.services = ['service1','service2']
        end
      end

      describe '.item_services_url' do
        it 'should return correct URL' do
          expect(provider.item_services_url).to eq 'www.example.com/repositories/repo/items/item.fmw/services'
        end
      end

      describe '.services_body' do
        context 'when no services' do
          it 'should return an empty string' do
            expect(provider.services_body([])).to eq('')
          end
        end
        context 'when 2 services' do
          it 'should return URI encoded string' do
            expect(provider.services_body(['service1','service2'])).to eq('services=service1&services=service2')
          end
        end
      end

      describe '.process_put_services_response' do
        context 'when response = 200' do
          it 'should call process_put_services_response_code_200' do
            response = mock('response')
            dummy_services = ['service1','service2']
            response.stubs(:code).returns(200)
            provider.expects(:process_put_services_response_code_200)
            provider.process_put_services_response(dummy_services,response)
          end
        end
        context 'when response = 207' do
          it 'should call process_put_services_response_code_207' do
            response = mock('response')
            dummy_services = ['service1','service2']
            response.stubs(:code).returns(207)
            provider.expects(:process_put_services_response_code_207).with(dummy_services,response)
            provider.process_put_services_response(dummy_services,response)
          end
        end
        context 'when something else' do
          it 'should raise exception' do
            response = mock('response')
            dummy_services = ['service1','service2']
            response.stubs(:code).returns(404)
            response.stubs(:to_str).returns('{"message":"dummy"}')
            expect{ provider.process_put_services_response(dummy_services,response) }.
              to raise_error(Puppet::Error,
                             /FME Rest API returned 404 when adding services to repo\/item\.fmw\. {"message"=>"dummy"}/)
          end
        end
      end

      describe '.process_put_services_response_code_200' do
        it 'should populate @property_hash' do
          provider.process_put_services_response_code_200(['service1','service2'])
          expect(provider.instance_variable_get('@property_hash')[:services]).to eq(['service1','service2'])
        end
      end

      describe '.process_put_services_response_code_207' do
        it 'should add sucessfully inserted services to @property_hash and raise error' do
          services_being_inserted = ['foo','service2']
          response = [
            { 'reason' => 'missing', 'name' => 'foo', 'status' => 409 },
            {
              'entity' => { 'displayName' => 'Test Service 2', 'name' => 'service2' },
              'name'   => 'service2',
              'status' => 200
            }
          ].to_json
          expect{ provider.process_put_services_response_code_207(services_being_inserted,response) }.
            to raise_error(Puppet::Error,
                           /The following services couldn't be added to repo\/item\.fmw: \["foo"\]/)
          expect(provider.instance_variable_get('@property_hash')[:services]).to eq(['service2'])
        end
      end
      describe '#checksum' do
        context 'when API success' do
          it 'should return checksum of data' do
            mock_data = 'DATA'
            expected_checksum = Digest::SHA256.new
            expected_checksum << mock_data

            stub_request(:get, 'http://www.example.com/repositories/repo/items/item.fmw').
              to_return(:status => 200, :body => mock_data)

            checksum = provider.checksum
            expect(checksum).to eq expected_checksum
          end
        end
      end
    end
  end
end
