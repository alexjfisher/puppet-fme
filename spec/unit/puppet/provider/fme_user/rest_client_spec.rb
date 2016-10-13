require 'spec_helper'

provider_class = Puppet::Type.type(:fme_user).provider(:rest_client)
describe provider_class do
  before :each do
    Fme::Helper.stubs(:get_url).returns('www.example.com')
  end
  let :resource do
    Puppet::Type.type(:fme_user).new(:name => 'testuser', :provider => :rest_client)
  end

  let :provider do
    resource.provider
  end

  describe 'instances' do
    it 'should have an instance method' do
      expect(described_class).to respond_to :instances
    end
    describe 'without users' do
      before :each do
        stub_request(:get, 'http://www.example.com/security/accounts?detail=high').
          to_return(:body => '[]')
      end
      it 'should return no resources' do
        expect(described_class.instances.size).to eq(0)
      end
    end
    describe 'with 1 user' do
      before :each do
        stub_request(:get, 'http://www.example.com/security/accounts?detail=high').
          to_return(:body =>
                    '[{"fullName": "test user",
                       "name": "test",
                       "roles": ["fmeuser"]}
                     ]')
      end
      it 'should return 1 resource' do
        expect(described_class.instances.size).to eq(1)
      end
      it 'should return the resource "test"' do
        expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'test',
          :fullname => 'test user',
          :roles    => ['fmeuser'],
          :provider => :rest_client
        })
      end
    end
    describe 'with 2 users' do
      before :each do
        stub_request(:get, 'http://www.example.com/security/accounts?detail=high').
          to_return(:body =>
                    '[{"fullName": "test user",
                       "name": "test",
                       "roles": ["fmeuser"]},
                      {"fullName": "test user2",
                       "name": "test2",
                       "roles": ["fmeuser","fmeadmin"]}
                     ]')
      end
      it 'should return 2 resources' do
        expect(described_class.instances.size).to eq(2)
      end
      it 'should return the resource "test"' do
        expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'test',
          :fullname => 'test user',
          :roles    => ['fmeuser'],
          :provider => :rest_client
        })
      end
      it 'should return the resource "test2"' do
        expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'test2',
          :fullname => 'test user2',
          :roles    => ['fmeuser', 'fmeadmin'],
          :provider => :rest_client
        })
      end
    end
  end
  describe 'prefetch' do
    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  describe 'get_new_params' do
    it 'should return a URI encoded parameter string' do
      resource[:password] = 'password'
      expect(provider.get_new_params).to eq('name=testuser&password=password')
    end
    context 'when resource fullname is set to "Test User"' do
      expected = 'name=testuser&fullName=Test+User'
      it "should return #{expected}" do
        resource[:fullname] = 'Test User'
        expect(provider.get_new_params).to eq(expected)
      end
    end
    context 'when fullname exists in @property_hash' do
      expected = 'name=testuser&fullName=Test+User+2'
      it "should return #{expected}" do
        provider.instance_variable_set(:@property_hash, { :fullname => 'Test User 2' })
        expect(provider.get_new_params).to eq(expected)
      end
    end
  end

  describe 'modify_user' do
    context 'when API returns response code 200' do
      before :each do
        stub_request(:put, 'http://www.example.com/security/accounts/testuser?detail=high&name=testuser').to_return(:status => 200, :body => '{"fullName": "test user","name": "testuser","roles": ["fmeuser"]}')
      end
      it 'should call response_to_property_hash to populate @property_hash' do
        provider.modify_user
        expect(provider.instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'testuser',
          :fullname => 'test user',
          :roles    => ['fmeuser'],
          :provider => :rest_client
        })
      end
    end
    context 'when API returns response code 421' do
      before :each do
        stub_request(:put, 'http://www.example.com/security/accounts/testuser?detail=high&name=testuser').to_return(:status => 421, :body => '{"message": "An error message"}')
      end
      it 'should raise a Puppet::Error with the API error message' do
        expect { provider.modify_user }.to raise_error(Puppet::Error, /FME Rest API returned 421 when modifying testuser\. {"message"=>"An error message"}/)
      end
    end
  end

  context 'when an instance' do
    it 'should indicate when the fme_user already exists' do
      provider = provider_class.new(:ensure => :present)
      expect(provider.exists?).to be_truthy
    end
    it 'should indicate when the fme_user does not exists' do
      provider = provider_class.new(:ensure => :absent)
      expect(provider.exists?).to be_falsey
    end
    describe 'is being created' do
      it 'should have a create method' do
        expect(provider).to respond_to(:create)
      end
      context 'when password is set' do
        before :each do
          stub_request(:post, 'http://www.example.com/security/accounts?name=testuser')
        end
        it 'should create user' do
          resource[:password] = 'password'
          provider.create
        end
      end
      context 'when password is not set' do
        it 'should raise exception' do
          expect { provider.create }.to raise_error(Puppet::Error, /password is mandatory/)
        end
      end
    end
    describe 'is being deleted' do
      it 'should have a destroy method' do
        expect(provider).to respond_to(:destroy)
      end
      it 'should set its @property_flush :ensure value to :absent' do
        provider.destroy
        expect(provider.instance_variable_get('@property_flush')).to eq({ :ensure => :absent })
      end
    end
    describe 'is being flushed' do
      context 'when being deleted' do
        before :each do
          stub_request(:delete, 'http://www.example.com/security/accounts/testuser')
          provider.instance_variable_set(:@property_flush, { :ensure => :absent })
        end
        it 'should delete' do
          provider.flush
        end
      end
      context 'when not being deleted' do
        context 'when password is not set' do
          it 'should raise exception' do
            expect { provider.flush }.to raise_error(Puppet::Error, /password is mandatory/)
          end
        end
        context 'when password is set' do
          it 'should call modify_user' do
            resource[:password] = 'password'
            provider.expects(:modify_user)
            provider.flush
          end
        end
      end
    end
  end
  describe 'when prefetching' do
    before :each do
      @resource_foo = Puppet::Type.type(:fme_user).new(:name => 'foo')
      @resource_bar = Puppet::Type.type(:fme_user).new(:name => 'bar')
      @resources = { 'foo' => @resource_foo, 'bar' => @resource_bar }
    end
    context 'when .instances returns some of the resources' do
      before :each do
        @only_provider_found = provider_class.new(@resource_foo)
        provider_class.stubs(:instances).returns([@only_provider_found])
      end
      describe '.prefetch' do
        context 'when provider for resource is found' do
          it 'should set the resource\'s provider' do
            @resource_foo.expects(:provider=).with(@only_provider_found)
            provider_class.prefetch(@resources)
          end
        end
        context 'when provider for resource is not found' do
          it 'should not set the resource\'s provider' do
            @resource_bar.expects(:provider=).never
            provider_class.prefetch(@resources)
          end
        end
      end
    end
  end
end
