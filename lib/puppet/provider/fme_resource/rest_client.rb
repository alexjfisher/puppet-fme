require 'json'
require 'rest-client' if Puppet.features.restclient?
require 'digest'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'fme', 'helper.rb'))
require File.join(File.dirname(__FILE__), '..', 'fme')

Puppet::Type.type(:fme_resource).provide(:rest_client) do
  confine :feature => :restclient
  if Puppet::Util::Platform.windows?
    confine :exists => 'C:/fme_api_settings.yaml'
  else
    confine :exists => '/etc/fme_api_settings.yaml'
  end

  def initialize(value={})
    super(value)
    @baseurl = Fme::Helper.get_url
  end

  def get_file_metadata(resource, path)
    url = "#{@baseurl}/resources/connections/#{resource}/filesys/#{path}"
    RestClient.get(url, { :params => { 'detail' => 'low', :depth => 0 }, :accept => :json }) do |response, request, result, &block|
      case response.code
      when 200
        extract_metadata_from_response(JSON.parse(response))
      when 404
        return nil
      else
        fail "FME Rest API returned #{response.code} when getting metadata for #{resource}:#{path}. #{JSON.parse(response)}"
      end
    end
  end

  def checksum
    url = "#{@baseurl}/resources/connections/#{resource[:resource]}/filesys#{resource[:path]}"
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

  def extract_metadata_from_response(json)
    metadata = { :ensure => :file      } if json['type'] == 'FILE'
    metadata = { :ensure => :directory } if json['type'] == 'DIR'
    metadata[:path] = "#{json['path']}#{json['name']}"
    metadata[:size] = json['size'] unless (json['size']).zero?
    metadata
  end

  def upload_file
    validate_source
    RestClient.post(get_post_url, read_source, post_params_for_upload_file) do |response, request, result, &block|
      fail "FME Rest API returned #{response.code} when uploading #{resource[:name]}. #{JSON.parse(response)}" unless response.code == 201
    end
  end

  def create_directory
    RestClient.post(get_post_url, create_directory_post_request_body) do |response, request, result, &block|
      fail "FME Rest API returned #{response.code} when creating directory #{resource[:name]}. #{JSON.parse(response)}" unless response.code == 201
    end
  end

  def create_directory_post_request_body
    directory_name = Pathname(resource[:path]).basename.to_s
    request_body = URI.encode_www_form(:directoryname => directory_name, :type => 'DIR')
    request_body
  end

  def has_source?
    return false if resource[:source].nil?
    true
  end

  def read_source
    file = File.new(resource[:source], 'rb')
    file.read
  end

  def validate_source
    fail 'source is required when creating new resource file' unless has_source?
  end

  def get_post_url
    "#{@baseurl}/resources/connections/#{resource[:resource]}/filesys#{Pathname(resource[:path]).dirname.to_s}"
  end

  def post_params_for_upload_file
    params = {
      :multipart           => true,
      :content_type        => 'application/octet-stream',
      :content_disposition => "attachment; filename=\"#{File.basename(resource[:path])}\"",
      :accept              => 'json',
      'detail'             => 'low',
      'createDirectories'  => true
    }
    params
  end

  def destroy
    url = "#{@baseurl}/resources/connections/#{resource[:resource]}/filesys/#{resource[:path]}"
    RestClient.delete(url)
    @property_hash.clear
  end

  def properties
    @property_hash = get_file_metadata(resource[:resource], resource[:path]) || { :ensure => :absent } if @property_hash.empty?
    @property_hash.dup
  end
end
