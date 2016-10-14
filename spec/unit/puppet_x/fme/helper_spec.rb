require 'spec_helper'

describe Fme::Helper do
  describe '.get_url' do
    it 'should call read_settings' do
      Fme::Helper.expects(:read_settings).returns('username' => 'user', 'password' => 'password')
      expect(Fme::Helper.get_url)
    end
    describe 'returned url' do
      describe 'port' do
        context 'when not set' do
          it 'should default to 80' do
            Fme::Helper.expects(:read_settings).returns('username' => 'user', 'password' => 'password')
            expect(Fme::Helper.get_url).to match(%r{:80})
          end
        end
        context 'when port is set to 443' do
          it 'should return URL with port 443' do
            Fme::Helper.expects(:read_settings).returns('username' => 'user', 'password' => 'password', 'port' => 443)
            expect(Fme::Helper.get_url).to match(%r{:443})
          end
        end
      end
      describe 'protocol' do
        context 'when not set' do
          it 'should return http URL' do
            Fme::Helper.expects(:read_settings).returns('username' => 'user', 'password' => 'password')
            expect(Fme::Helper.get_url).to match(%r{http://})
          end
        end
        context 'when set to https' do
          it 'should return https URL' do
            Fme::Helper.expects(:read_settings).returns('username' => 'user', 'password' => 'password', 'protocol' => 'https')
            expect(Fme::Helper.get_url).to match(%r{https://})
          end
        end
      end
      describe 'host' do
        context 'when not set' do
          it 'should return localhost URL' do
            Fme::Helper.expects(:read_settings).returns('username' => 'user', 'password' => 'password')
            expect(Fme::Helper.get_url).to match(%r{@localhost:})
          end
        end
        context 'when set to example.com' do
          it 'should return URL for example.com' do
            Fme::Helper.expects(:read_settings).returns('username' => 'user', 'password' => 'password', 'host' => 'example.com')
            expect(Fme::Helper.get_url).to match(%r{@example.com:})
          end
        end
      end
    end
  end

  describe '.settings_file' do
    context 'on windows' do
      before :each do
        Facter.clear
        Facter.stubs(:fact).with(:kernel).returns Facter.add(:kernel) { setcode { 'windows' } }
      end
      it 'should return C:/fme_api_settings.yaml' do
        expect(Fme::Helper.settings_file).to eq('C:/fme_api_settings.yaml')
      end
    end
    context 'on linux' do
      before :each do
        Facter.clear
        Facter.stubs(:fact).with(:kernel).returns Facter.add(:kernel) { setcode { 'Linux' } }
      end
      it 'should return /etc/fme_api_settings.yaml' do
        expect(Fme::Helper.settings_file).to eq('/etc/fme_api_settings.yaml')
      end
    end
  end

  describe '.validate_settings' do
    context 'with no settings' do
      it 'should raise an exception' do
        expect { Fme::Helper.validate_settings(nil) }.to raise_error(Puppet::Error, %r{Can't find settings})
      end
    end
    context 'with missing username' do
      it 'should raise an exception' do
        expect { Fme::Helper.validate_settings('{}') }.to raise_error(Puppet::Error, %r{Can't find username})
      end
    end
    context 'with missing password' do
      it 'should raise an exception' do
        expect { Fme::Helper.validate_settings("{:username => 'user'}") }.to raise_error(Puppet::Error, %r{Can't find password})
      end
    end
  end

  describe '.read_settings' do
    context 'when settings file contains YAML' do
      before :each do
        File.stubs(:read).with('/path/to/settings').returns("---\nusername: user\npassword: password")
      end
      it 'should parse settings file and return a hash' do
        Fme::Helper.expects(:settings_file).returns('/path/to/settings')
        expect(Fme::Helper.read_settings).to eq('username' => 'user', 'password' => 'password')
      end
    end
    context 'when settings file can not be parsed as YAML' do
      before :each do
        File.stubs(:read).with('/path/to/settings').returns("{'username'=>'user'}")
      end
      it 'should raise exception' do
        Fme::Helper.expects(:settings_file).returns('/path/to/settings')
        expect { Fme::Helper.read_settings }.to raise_error(Puppet::Error, %r{Error when reading FME API settings file})
      end
    end
  end

  describe '.response_to_property_hash' do
    it 'parses JSON' do
      expect(Fme::Helper.response_to_property_hash('{"name": "testuser"}')).to include(:name => 'testuser')
    end
    it 'merges :ensure and :provider' do
      expect(Fme::Helper.response_to_property_hash('{"name": "testuser"}')).to include(:ensure => :present, :provider => :rest_client)
    end
    it 'converts keys to symbols' do
      expect(Fme::Helper.response_to_property_hash('{"name": "testuser"}')).to include(:name => 'testuser')
    end
    it 'downcases keys' do
      expect(Fme::Helper.response_to_property_hash('{"fullName": "Test User"}')).to include(:fullname => 'Test User')
    end
  end
end
