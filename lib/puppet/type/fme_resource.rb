require 'puppet/parameter/boolean'
Puppet::Type.newtype(:fme_resource) do
  desc 'Puppet type to manage FME shared resources'

  def self.title_patterns
    identity = ->(x) { x }
    [
      [
        %r{^([^:]+)$},
        [
          [:name, identity]
        ]
      ],
      [
        %r{^((.*):(.*))$},
        [
          [:name,     identity],
          [:resource, identity],
          [:path,     identity]
        ]
      ]
    ]
  end

  validate do
    raise Puppet::Error, 'fme_resource: path is required or use <RESOURCE>:<PATH> style resource title'     unless self[:path]
    raise Puppet::Error, 'fme_resource: resource is required or use <RESOURCE>:<PATH> style resource title' unless self[:resource]
  end

  ensurable do
    newvalue(:file) do
      current = retrieve
      if current == :absent
        provider.upload_file
      elsif current == :file
        @original_size = provider.properties[:size]
        provider.destroy
        provider.upload_file
      elsif current == :directory
        raise 'Cannot replace a directory with a file!'
      end
    end

    aliasvalue(:present, :file)

    newvalue(:directory) do
      raise Puppet::Error, 'Cannot replace a file with a directory!' if retrieve == :file
      provider.create_directory
    end

    newvalue(:absent) do
      provider.destroy
    end

    def retrieve
      provider.properties[:ensure]
    end

    def insync?(is)
      if should == :file && is == :file
        return false unless sizes_match?
        if @resource.original_parameters[:checksum]
          return false unless checksums_match?
        end
      end
      super
    end

    def sizes_match?
      provider.properties[:size] == size_of_source
    end

    def checksums_match?
      provider.checksum == checksum_of_source
    end

    def change_to_s(currentvalue, newvalue)
      return 'uploaded new file' if new_file?(currentvalue, newvalue)
      return 'created directory' if new_directory?(currentvalue, newvalue)
      return 'deleted file'      if deleted_file?(currentvalue, newvalue)
      return 'deleted directory' if deleted_directory?(currentvalue, newvalue)
      "replaced file of size #{@original_size} bytes with one of #{size_of_source} bytes"
    end

    def size_of_source
      File.size?(@resource.original_parameters[:source])
    end

    def checksum_of_source
      sha256 = Digest::SHA256.new
      open(@resource.original_parameters[:source]) do |s|
        while chunk = s.read(1024) # rubocop:disable Lint/AssignmentInCondition
          sha256 << chunk
        end
      end
      sha256
    end

    def new_file?(currentvalue, newvalue)
      currentvalue == :absent && newvalue == :file
    end

    def new_directory?(currentvalue, newvalue)
      currentvalue == :absent && newvalue == :directory
    end

    def deleted_file?(currentvalue, newvalue)
      currentvalue == :file && newvalue == :absent
    end

    def deleted_directory?(currentvalue, newvalue)
      currentvalue == :directory && newvalue == :absent
    end
  end

  newparam(:source) do
    desc 'The file to upload.  Must be the absolute path to a file.'
    validate do |value|
      raise Puppet::Error, "'source' file path must be absolute, not '#{value}'" unless Puppet::Util.absolute_path?(value)
    end
  end

  newparam(:path, :namevar => true) do
    validate do |value|
      raise Puppet::Error, "'path' file path must be absolute, not '#{value}'" unless Puppet::Util.absolute_path?(value)
    end
  end

  newparam(:checksum, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Whether to fetch remote files and checksum them'
    defaultto :false
  end

  newparam(:resource, :namevar => true) do
    # TODO: Rename this to something less confusing??
  end

  newparam(:name) do
    desc 'The default namevar'
    munge do |_discard|
      shared_resource = @resource.original_parameters[:resource]
      path            = @resource.original_parameters[:path]
      "#{shared_resource}:#{path}"
    end
  end
end
