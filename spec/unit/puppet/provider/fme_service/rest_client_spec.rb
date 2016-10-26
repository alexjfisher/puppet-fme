require 'spec_helper'

provider_class = Puppet::Type.type(:fme_service).provider(:rest_client)

RSpec.describe provider_class do
  before :each do
    Fme::Helper.stubs(:get_url).returns('www.example.com')
  end
  let(:name)     { 'my_service' }
  let(:resource) { Puppet::Type::Fme_service.new(resource_properties) }
  let(:provider) { provider_class.new(resource) }
  let(:resource_properties) do
    {
      name: name
    }
  end

  describe 'property setters' do
    describe '#url=' do
      it 'calls update_property with \'URL\' and value' do
        provider.expects(:update_property).with('URL', 'value')
        provider.url = 'value'
      end
    end

    describe '#description=' do
      it 'calls update_property with \'description\' and value' do
        provider.expects(:update_property).with('description', 'value')
        provider.description = 'value'
      end
    end

    describe '#display_name=' do
      it 'calls update_property with \'displayName\' and value' do
        provider.expects(:update_property).with('displayName', 'value')
        provider.display_name = 'value'
      end
    end

    describe '#enabled=' do
      it 'calls update_property with \'enabled\' and value' do
        provider.expects(:update_property).with('enabled', 'value')
        provider.enabled = 'value'
      end
    end
  end
  describe '#update_property' do
    context 'when updating displayName' do
      context 'when API returns success' do
        before :each do
          stub_request(:put, 'http://www.example.com/services/my_service/displayName?detail=low').
            with(:body => { 'value' => 'value' },
                 :headers => { 'Accept' => 'application/json', 'Content-Type' => 'application/x-www-form-urlencoded' }).
            to_return(:status => 200, :body => '')
        end
        it 'sets :display_name in @property_hash' do
          provider.update_property('displayName', 'value')
          expect(provider.instance_variable_get('@property_hash')).to eq(:display_name => 'value')
        end
      end
      context 'when API returns failure' do
        before :each do
          stub_request(:put, 'http://www.example.com/services/my_service/displayName?detail=low').
            with(:body => { 'value' => 'value' },
                 :headers => { 'Accept' => 'application/json', 'Content-Type' => 'application/x-www-form-urlencoded' }).
            to_return(:status => 421, :body => '{"message": "An error message"}')
        end
        it 'raises an error' do
          expect { provider.update_property('displayName', 'value') }.
            to raise_error(Puppet::Error,
                           %r[FME Rest API returned 421 when modifying my_service displayName\. {"message"=>"An error message"}])
        end
      end
    end
  end
end
