require 'json'
require 'rest-client' if Puppet.features.restclient?

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'fme', 'helper.rb'))
require File.join(File.dirname(__FILE__), '..', 'fme')

Puppet::Type.type(:fme_user).provide(:rest_client, :parent => Puppet::Provider::Fme) do
  confine :feature => :restclient
  if Puppet::Util::Platform.windows?
    confine :exists => 'C:/fme_api_settings.yaml'
  else
    confine :exists => '/etc/fme_api_settings.yaml'
  end

  mk_resource_methods

  def self.instances
    baseurl = Fme::Helper.get_url
    url = "#{baseurl}/security/accounts"
    response = RestClient.get(url, { :params => { 'detail' => 'high' }, :accept => :json })
    users = JSON.parse(response)
    users.collect do |user|
      user_properties = {}
      user_properties[:ensure]   = :present
      user_properties[:provider] = :rest_client
      user_properties[:name]     = user['name']
      user_properties[:fullname] = user['fullName']
      user_properties[:roles]    = user['roles']
      new(user_properties)
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def create
    if resource[:password].nil?
      raise Puppet::Error, 'Sorry, password is mandatory when creating fme_users'
    end
    baseurl = Fme::Helper.get_url
    url = "#{baseurl}/security/accounts"
    params = { 'name' => resource[:name] }
    RestClient.post(url, '', :params => params, :content_type => 'application/x-www-form-urlencoded', :accept => :json)
  end

  def flush
    if @property_flush[:ensure] == :absent
      RestClient.delete("#{Fme::Helper.get_url}/security/accounts/#{resource[:name]}", :accept => :json)
      @property_hash[:ensure] = :absent
    else
      raise Puppet::Error, 'Sorry, password is mandatory when modifying fme_users' if resource[:password].nil?
      modify_user
    end
  end

  def modify_user
    url = "#{Fme::Helper.get_url}/security/accounts/#{resource[:name]}"

    RestClient.put("#{url}?detail=high&#{get_new_params}", '', { :content_type => 'application/x-www-form-urlencoded', :accept => :json }) do |response, request, result, &block|
      case response.code
      when 200
        @property_hash = Fme::Helper.response_to_property_hash(response)
      else
        raise Puppet::Error, "FME Rest API returned #{response.code} when modifying #{resource[:name]}. #{JSON.parse(response)}"
      end
    end
  end

  # Helper methods
  def get_new_params
    URI.encode_www_form(
      {
        :name     => resource[:name],
        :password => resource[:password],
        :fullName => (resource[:fullname] || @property_hash[:fullname]),
        :roles    => (resource[:roles]    || @property_hash[:roles])
      }.delete_if{ |k, v| v.nil? }
    )
  end
end
