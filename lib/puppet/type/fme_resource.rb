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
      provider.upload_file
    end

    aliasvalue(:present, :file)

    newvalue(:directory) do
      provider.create_directory
    end

    newvalue(:absent) do
      provider.destroy
    end

    def retrieve
      provider.properties[:ensure]
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
