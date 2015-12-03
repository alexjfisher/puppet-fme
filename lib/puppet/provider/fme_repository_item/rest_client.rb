require 'json'
require 'rest-client' if Puppet.features.restclient?

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'fme', 'helper.rb'))

Puppet::Type.type(:fme_repository_item).provide(:rest_client) do
  confine :feature => :restclient

  mk_resource_methods

  def initialize(value={})
    super(value)
    @baseurl = Fme::Helper.get_url
  end

  def self.get_repos
    url = "#{Fme::Helper.get_url}/repositories"
    response = RestClient.get(url, {:params => {'detail' => 'high'}, :accept => :json})
    repos = JSON.parse(response)
    repos_array = []
    repos.each do |repo|
      repos_array.push(repo['name'])
    end
    repos_array
  end

  def self.get_items_from_repo(repo)
    url = "#{Fme::Helper.get_url}/repositories/#{repo}/items"
    response = RestClient.get(url, {:params => {'detail' => 'high'}, :accept => :json})
    items = JSON.parse(response)
    items.collect do |item|
      item_properties = { ensure:         :present,
                          provider:       :rest_client,
                          item:           item['name'],
                          description:    item['description'],
                          item_title:     item['title'],
                          type:           item['type'],
                          last_save_date: item['lastSaveDate'],
                          repository:     repo,
                          name:           "#{repo}/#{item['name']}" }
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

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    url = "#{@baseurl}/repositories/#{resource[:repository]}/items"
    RestClient.post(url, read_item_from_file, get_post_params) do |response, request, result, &block|
      case response.code
      when 201
        set_property_hash_from_create_response response
      else
        raise Puppet::Error, "FME Rest API returned #{response.code} when creating #{resource[:name]}. #{JSON.parse(response)}"
      end
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
    @property_hash = { ensure:         :present,
                       provider:       :rest_client,
                       item:           response['name'],
                       description:    response['description'],
                       item_title:     response['title'],
                       type:           response['type'],
                       last_save_date: response['lastSaveDate'],
                       repository:     resource[:repository],
                       name:           "#{resource[:repository]}/#{response['name']}" }
  end

  def destroy
    RestClient.delete("#{@baseurl}/repositories/#{resource[:repository]}/items/#{resource[:item]}", :accept => :json)
    @property_hash[:ensure] = :absent
  end
end
