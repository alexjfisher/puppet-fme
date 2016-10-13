require 'json'
require 'rest-client' if Puppet.features.restclient?
require 'digest'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'fme', 'helper.rb'))
require File.join(File.dirname(__FILE__), '..', 'fme')

Puppet::Type.type(:fme_repository_item).provide(:rest_client, :parent => Puppet::Provider::Fme) do
  confine :feature => :restclient
  if Puppet::Util::Platform.windows?
    confine :exists => 'C:/fme_api_settings.yaml'
  else
    confine :exists => '/etc/fme_api_settings.yaml'
  end

  mk_resource_methods

  def initialize(value={})
    super(value)
    @baseurl = Fme::Helper.get_url
  end

  def self.get_repos
    url = "#{Fme::Helper.get_url}/repositories"
    response = RestClient.get(url, :params => { 'detail' => 'high' }, :accept => :json)
    repos = JSON.parse(response)
    repos_array = []
    repos.each do |repo|
      repos_array.push(repo['name'])
    end
    repos_array
  end

  def self.get_items_from_repo(repo)
    url = "#{Fme::Helper.get_url}/repositories/#{repo}/items"
    response = RestClient.get(url, :params => { 'detail' => 'high' }, :accept => :json)
    items = JSON.parse(response)
    items.collect do |item|
      item_properties = { :ensure         => :present,
                          :provider       => :rest_client,
                          :item           => item['name'],
                          :description    => item['description'],
                          :item_title     => item['title'],
                          :type           => item['type'],
                          :last_save_date => item['lastSaveDate'],
                          :repository     => repo,
                          :name           => "#{repo}/#{item['name']}" }
      item_properties
    end
  end

  def self.instances
    instances = []
    get_repos.each do |repo|
      get_items_from_repo(repo).each do |item|
        instances.push(new(item))
      end
    end
    instances
  end

  def create
    fail 'source is required when creating new repository item' if resource[:source].nil?
    RestClient.post(create_url, read_item_from_file, get_post_params) do |response, request, result, &block|
      process_create_response(response)
    end
  end

  def create_url
    "#{@baseurl}/repositories/#{resource[:repository]}/items"
  end

  def process_create_response(response)
    case response.code
    when 201
      set_property_hash_from_create_response response
      self.services = resource[:services] unless resource[:services].nil?
    else
      raise Puppet::Error, "FME Rest API returned #{response.code} when creating #{resource[:name]}. #{JSON.parse(response)}"
    end
  end

  def get_post_params
    params = { 'repository'         => resource[:repository],
               'detail'             => 'low',
               :multipart           => true,
               :content_type        => 'application/octet-stream',
               :content_disposition => "attachment; filename=\"#{File.basename(resource[:source])}\"",
               :accept              => 'json' }
    params
  end

  def read_item_from_file
    data = File.new(resource[:source])
    data
  end

  def set_property_hash_from_create_response(response)
    response = JSON.parse(response)
    @property_hash = { :ensure         => :present,
                       :provider       => :rest_client,
                       :item           => response['name'],
                       :description    => response['description'],
                       :item_title     => response['title'],
                       :type           => response['type'],
                       :last_save_date => response['lastSaveDate'],
                       :repository     => resource[:repository],
                       :name           => "#{resource[:repository]}/#{response['name']}" }
  end

  def destroy
    Puppet.debug 'Deleting repository_item'
    RestClient.delete("#{@baseurl}/repositories/#{resource[:repository]}/items/#{resource[:item]}", :accept => :json)
    @property_hash.clear
  end

  def services
    response = RestClient.get(item_services_url, :accept => :json)
    services = JSON.parse(response)
    services.map { |x| x['name'] }
  end

  def services=(services)
    RestClient.put(item_services_url, services_body(services), :accept => :json, :content_type => 'application/x-www-form-urlencoded') do |response, request, result, &block|
      process_put_services_response(services, response)
    end
  end

  def item_services_url
    "#{Fme::Helper.get_url}/repositories/#{resource[:repository]}/items/#{resource[:item]}/services"
  end

  def services_body(services)
    URI.encode_www_form(:services => services)
  end

  def process_put_services_response(services, response)
    case response.code
    when 200
      process_put_services_response_code_200(services)
    when 207
      process_put_services_response_code_207(services, response)
    else
      raise Puppet::Error, "FME Rest API returned #{response.code} when adding services to #{resource[:name]}. #{JSON.parse(response)}"
    end
  end

  def process_put_services_response_code_200(services)
    @property_hash[:services] = services
  end

  def process_put_services_response_code_207(services, response)
    # "The response body contains information about the result of the registration operation, indicating success or error status for each service"
    @property_hash[:services] = JSON.parse(response).map { |service| service['name'] if service['status'] == 200 }.compact
    raise Puppet::Error, "The following services couldn't be added to #{resource[:name]}: #{services - @property_hash[:services]}"
  end

  def checksum
    url = "#{@baseurl}/repositories/#{resource[:repository]}/items/#{resource[:item]}"
    sha256_checksum = Digest::SHA256.new
    perform_checksum = Proc.new do |http_response|
      http_response.read_body do |chunk|
        sha256_checksum << chunk
      end
    end
    headers = { 'accept' => 'application/octet-stream' }
    response = RestClient::Request.execute(:method => :get, :url => url, :headers => headers, :block_response => perform_checksum)
    raise Puppet::Error, "Error calculating checksum #{response.code}" unless response.code == '200'
    sha256_checksum
  end
end
