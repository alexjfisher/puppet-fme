require 'yaml'
require 'json'

module Fme
  class Helper
    def self.get_url
      settings = read_settings

      host     = settings['host'] ? settings['host'] : 'localhost'
      port     = settings['port'] ? settings['port'] : 80
      protocol = settings['protocol'] ? settings['protocol'] : 'http'
      username = settings['username']
      password = settings['password']

      url = "#{protocol}://#{username}:#{password}@#{host}:#{port}/fmerest/v2"
      url
    end

    def self.settings_file
      case Facter.value(:kernel)
      when 'Linux'
        return '/etc/fme_api_settings.yaml'
      when 'windows'
        return 'C:/fme_api_settings.yaml'
      end
    end

    def self.read_settings
      begin
        settings = YAML.load(File.read(settings_file))
      rescue ScriptError, RuntimeError => e
        raise Puppet::Error, "Error when reading FME API settings file: #{e}"
      end
      validate_settings(settings)
      settings
    end

    def self.validate_settings(settings)
      raise Puppet::Error, "Can't find settings" if settings.nil?
      raise Puppet::Error, "Can't find username in #{settings_file}" if settings['username'].nil?
      raise Puppet::Error, "Can't find password in #{settings_file}" if settings['password'].nil?
    end

    def self.response_to_property_hash(response)
      JSON.parse(response).merge!(:ensure => :present, :provider => :rest_client).inject({}) { |memo, (k, v)| memo[k.downcase.to_sym] = v; memo }
    end
  end
end
