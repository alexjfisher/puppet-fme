require 'json'
require 'rest-client' if Puppet.features.restclient?

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'fme', 'helper.rb'))
require File.join(File.dirname(__FILE__), '..', 'fme')

Puppet::Type.type(:fme_repository).provide(:rest_client, :parent => Puppet::Provider::Fme) do
  confine :feature => :restclient
  if Puppet::Util::Platform.windows?
    confine :exists => 'C:/fme_api_settings.yaml'
  else
    confine :exists => '/etc/fme_api_settings.yaml'
  end

  mk_resource_methods

  def initialize(value = {})
    super(value)
    @baseurl = Fme::Helper.get_url
  end

  def self.instances
    url = "#{Fme::Helper.get_url}/repositories"
    response = RestClient.get(url, :params => { 'detail' => 'high' }, :accept => :json)
    repos = JSON.parse(response)
    repos.collect do |repo|
      repo_properties = {}
      repo_properties[:ensure]      = :present
      repo_properties[:provider]    = :rest_client
      repo_properties[:name]        = repo['name']
      repo_properties[:description] = repo['description']
      new(repo_properties)
    end
  end

  def create
     url = "#{@baseurl}/repositories"
     params = { 'name' => resource[:name], 'description' => resource[:description] }.delete_if { |k, v| v.nil? }
     RestClient.post(url, '', :params => params, :content_type => 'application/x-www-form-urlencoded', :accept => :json) do |response, request, result, &block|
       case response.code
       when 201
         @property_hash = Fme::Helper.response_to_property_hash(response)
       else
         # Raise an error for all other response codes. Examples are
         # 401 - 'Unauthorised'
         # 409 - 'The repository already exists' (This shouldn't be possible)!
         # 422 - 'Some or all of the input parameters are invalid'
         raise Puppet::Error, "FME Rest API returned #{response.code} when creating #{resource[:name]}. #{JSON.parse(response)}"
       end
     end
  end

  def destroy
    RestClient.delete("#{@baseurl}/repositories/#{resource[:name]}", :accept => :json)
    @property_hash[:ensure] = :absent
  end

  def description=(value)
    raise Puppet::Error, "FME API doesn't support updating the repository description"
  end
end
