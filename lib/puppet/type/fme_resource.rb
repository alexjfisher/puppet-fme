Puppet::Type.newtype(:fme_resource) do
  desc "Puppet type to manage FME shared resources"

  def self.title_patterns
    identity = lambda {|x| x}
    [
      [
        /^([^:]+)$/,
        [
          [:name, identity ]
        ]
      ],
      [
        /^((.*):(.*))$/,
        [
          [:name,     identity ],
          [:resource, identity ],
          [:path,     identity ]
        ]
      ]
    ]
  end

  validate do
    fail 'fme_resource: path is required or use <RESOURCE>:<PATH> style resource title'     unless self[:path]
    fail 'fme_resource: resource is required or use <RESOURCE>:<PATH> style resource title' unless self[:resource]
  end

  ensurable do
    newvalue(:file) do
      current = self.retrieve
      if current == :absent
        provider.upload_file
      elsif current == :file
        @original_size = provider.properties[:size]
        provider.destroy
        provider.upload_file
      elsif current == :directory
        fail "Cannot replace a directory with a file!"
      end
    end

    aliasvalue(:present, :file)

    newvalue(:directory) do
      fail "Cannot replace a file with a directory!" if self.retrieve == :file
      provider.create_directory
    end

    newvalue(:absent) do
      provider.destroy
    end

    def retrieve
      provider.properties[:ensure]
    end

    def insync?(is)
      return false if should == :file and is == :file and provider.properties[:size] != size_of_source
      super
    end

    def change_to_s(currentvalue, newvalue)
      return "uploaded new file" if new_file?(currentvalue, newvalue)
      return "created directory" if new_directory?(currentvalue, newvalue)
      return "deleted file"      if deleted_file?(currentvalue, newvalue)
      return "deleted directory" if deleted_directory?(currentvalue, newvalue)
      "replaced file of size #{@original_size} bytes with one of #{size_of_source} bytes"
    end

    def size_of_source
      File.size?(@resource.original_parameters[:source])
    end

    def new_file?(currentvalue, newvalue)
      currentvalue == :absent and newvalue == :file
    end

    def new_directory?(currentvalue, newvalue)
      currentvalue == :absent and newvalue == :directory
    end

    def deleted_file?(currentvalue, newvalue)
      currentvalue == :file and newvalue == :absent
    end

    def deleted_directory?(currentvalue, newvalue)
      currentvalue == :directory and newvalue == :absent
    end
  end

  newparam(:source) do
    desc "The file to upload.  Must be the absolute path to a file."
    validate do |value|
      fail "'source' file path must be absolute, not '#{value}'" unless Puppet::Util.absolute_path?(value)
    end
  end

  newparam(:path, :namevar => true) do
    validate do |value|
      fail "'path' file path must be absolute, not '#{value}'" unless Puppet::Util.absolute_path?(value)
    end
  end

  newparam(:resource, :namevar => true) do
    #TODO Rename this to something less confusing??
  end

  newproperty(:size) do
    validate { |val| fail "size is read-only" }
  end

  newparam(:name) do
    desc "The default namevar"
    munge do |discard|
      shared_resource = @resource.original_parameters[:resource]
      path            = @resource.original_parameters[:path]
      "#{shared_resource.to_s}:#{path.to_s}"
    end
  end
end
