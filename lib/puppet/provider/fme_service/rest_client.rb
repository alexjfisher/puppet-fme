require 'json'
require 'rest-client' if Puppet.features.restclient?

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'fme', 'helper.rb'))
require File.join(File.dirname(__FILE__), '..', 'fme')

class String
  def underscore
    gsub(%r{::}, '/').
      gsub(%r{([A-Z]+)([A-Z][a-z])}, '\1_\2').
      gsub(%r{([a-z\d])([A-Z])}, '\1_\2').
      tr('-', '_').
      downcase
  end
end

Puppet::Type.type(:fme_service).provide(:rest_client, :parent => Puppet::Provider::Fme) do
  confine :feature => :restclient
  if Puppet::Util::Platform.windows?
    confine :exists => 'C:/fme_api_settings.yaml'
  else
    confine :exists => '/etc/fme_api_settings.yaml'
  end

  mk_resource_methods

  def self.instances
    retrieve_all_services.map do |service|
      service_properties = {}
      service_properties[:ensure]       = :present
      service_properties[:provider]     = :rest_client
      service_properties[:name]         = service['name']
      service_properties[:url]          = service['url']
      service_properties[:description]  = service['description']
      service_properties[:display_name] = service['displayName']
      service_properties[:enabled]      = service['enabled']
      new(service_properties)
    end
  end

  def self.retrieve_all_services(detail = 'low')
    url = "#{Fme::Helper.get_url}/services"
    response = RestClient.get(url, :params => { 'detail' => detail }, :accept => :json)
    JSON.parse(response)
  end

  def url=(should)
    update_property('URL', should)
  end

  def description=(should)
    update_property('description', should)
  end

  def display_name=(should)
    update_property('displayName', should)
  end

  def enabled=(should)
    update_property('enabled', should)
  end

  def update_property(property, value)
    url = "#{Fme::Helper.get_url}/services/#{resource[:name]}/#{property}"
    form_data = URI.encode_www_form('value' => value)
    RestClient.put("#{url}?detail=low", form_data, :content_type => 'application/x-www-form-urlencoded', :accept => :json) do |response, _request, _result|
      case response.code
      when 200
        @property_hash[property.underscore.to_sym] = value
      else
        raise Puppet::Error, "FME Rest API returned #{response.code} when modifying #{resource[:name]} #{property}. #{JSON.parse(response)}"
      end
    end
  end
end
