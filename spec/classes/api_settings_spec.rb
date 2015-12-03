require 'spec_helper'

describe 'fme::api_settings' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "without any parameters" do
          it { is_expected.not_to compile }
        end
        context "with username and password" do
          let(:params) { { :username => 'user', :password => 'secret' } }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('Fme::Api_settings') }
          it { is_expected.to create_file('/etc/fme_api_settings.yaml') }
        end
      end
    end
    context "on windows" do
      let(:facts) { { :kernel => 'windows' } }
      context "with username and password" do
        let(:params) { { :username => 'user', :password => 'secret' } }
        it { is_expected.to create_file('C:/fme_api_settings.yaml') }
      end
    end
  end
end
