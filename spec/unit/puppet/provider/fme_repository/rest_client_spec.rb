require 'spec_helper'

provider_class = Puppet::Type.type(:fme_repository).provider(:rest_client)

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

      context 'when there is 1 repository' do
        before :each do
          stub_request(:get, 'http://www.example.com/repositories?detail=high').
            to_return(:body => [{ 'name' => 'repo1', 'description' => 'Test repo 1' }].to_json)
        end
        it 'should return 1 resource' do
          expect(described_class.instances.size).to eq(1)
        end

        it 'should return the resource "repo1"' do
          expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
            :ensure      => :present,
            :provider    => :rest_client,
            :name        => 'repo1',
            :description => 'Test repo 1'
          })
        end
      end

      context 'when there are 2 repositories' do
        before :each do
          stub_request(:get, 'http://www.example.com/repositories?detail=high').
            to_return(:body =>
                      [
                        { 'name' => 'repo1', 'description' => 'Test repo 1' },
                        { 'name' => 'repo2', 'description' => 'Test repo 2' }
                      ].to_json)
        end
        it 'should return 2 resources' do
          expect(described_class.instances.size).to eq(2)
        end

        it 'should return the resource "repo1"' do
          expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
            :ensure      => :present,
            :provider    => :rest_client,
            :name        => 'repo1',
            :description => 'Test repo 1'
          })
        end

        it 'should return the resource "repo2"' do
          expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
            :ensure      => :present,
            :provider    => :rest_client,
            :name        => 'repo2',
            :description => 'Test repo 2'
          })
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
    let(:name) { 'myrepo' }
    let(:resource) do
      Puppet::Type.type(:fme_repository).new(
        :name     => name,
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
      it 'should indicate when the fme_repository already exists' do
        provider = provider_class.new(:ensure => :present)
        expect(provider.exists?).to be_truthy
      end
      it 'should indicate when the fme_repository does not exist' do
        provider = provider_class.new(:ensure => :absent)
        expect(provider.exists?).to be_falsey
      end
    end

    describe 'is being created' do
      it 'should have a create method' do
        expect(provider).to respond_to(:create)
      end
      context 'when API returns success' do
        before :each do
          stub_request(:post, 'http://www.example.com/repositories?description=a%20test%20repo&name=myrepo').
            to_return(:status => 201, :body => { 'name' => 'myrepo', 'description' => 'a test repo' }.to_json)
        end
        it 'should create a repository' do
          resource[:description] = 'a test repo'
          provider.create
          expect(provider.instance_variable_get('@property_hash')).to eq({
            :ensure      => :present,
            :provider    => :rest_client,
            :name        => 'myrepo',
            :description => 'a test repo'
          })
        end
      end

      context 'when API returns an error' do
        before :each do
          stub_request(:post, 'http://www.example.com/repositories?name=myrepo').
            to_return(:status => 401, :body => { 'message' => 'Authentication failed: Failed to login' }.to_json)
        end
        it 'should raise an exception' do
          expect { provider.create }.to raise_error(Puppet::Error, /FME Rest API returned 401 when creating myrepo/)
        end
      end
    end

    describe 'is being destroyed' do
      before :each do
        stub_request(:delete, 'http://www.example.com/repositories/myrepo').
          to_return(:status => 200)
      end
      it 'should be deleted' do
        provider.destroy
        expect(provider.instance_variable_get('@property_hash')).to eq({ :ensure => :absent })
      end
    end

    describe 'is having description updated' do
      it 'should raise exception' do
        expect { provider.description = 'new description' }.
          to raise_error(Puppet::Error, /FME API doesn\'t support updating the repository description/)
      end
    end
  end
end
