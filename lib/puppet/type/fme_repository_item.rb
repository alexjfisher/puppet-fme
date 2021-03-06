Puppet::Type.newtype(:fme_repository_item) do
  desc 'Puppet type that manages FME repository item'

  ensurable do
    newvalue(:present) do
      provider.destroy if provider.exists?
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto(:present)

    def insync?(is)
      return false if is == :present && !items_match?
      super
    end

    def items_match?
      checksum_of_source == provider.checksum
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
  end

  autorequire(:file) do
    Fme::Helper.settings_file
  end

  autorequire(:fme_repository) do
    self[:repository]
  end

  def self.title_patterns
    [
      [
        %r{^(.*)/(.*)$}, # pattern to parse <repository>/<item>
        [
          [:repository, ->(x) { x }],
          [:item,       ->(x) { x }]
        ]
      ],
      [
        %r{(.*)}, # Catch all workaround to avoid 'No set of title patterns matched the title'
        [
          [:dummy, ->(_x) { '' }]
        ]
      ]
    ]
  end

  validate do
    raise Puppet::Error, "'name' should not be used" unless @original_parameters[:name].nil? || @original_parameters[:name] == "#{@original_parameters[:repository]}/#{@original_parameters[:item]}"
    if match = @title.match(%r{^(.*)/(.*)$}) # rubocop:disable Lint/AssignmentInCondition
      raise Puppet::Error, "'repository' parameter #{self[:repository]} must match resource title #{@title} or be omitted" unless match.captures[0] == self[:repository]
      raise Puppet::Error, "'item' parameter #{self[:item]} must match resource title #{@title} or be omitted" unless match.captures[1] == self[:item]
    end
  end

  newparam(:dummy) do
    validate { |value| raise Puppet::Error, "dummy parameter shouldn't be used" unless value.empty? }
  end

  newparam(:repository, :namevar => true) do
    desc 'Name of the repository containing the item'
  end

  newparam(:item, :namevar => true) do
    desc 'The name of the item'
    newvalues(%r{[^/]+\.(?:|fmw|fds|fmx|fmwt)})
  end

  newparam(:name, :namevar => true) do
    desc 'The default namevar'
    defaultto ''
    munge do |value|
      if value.empty? && resource[:repository] && resource[:item]
        "#{resource[:repository]}/#{resource[:item]}"
      else
        raise Puppet::Error, "Use resource name style <repository>/<item> OR specify both 'repository' and 'item'" unless value =~ %r{^(.*)/(.*)$}
        value
      end
    end
  end

  newparam(:source) do
    desc 'The file to upload.  Must be the absolute path to a file.'
    validate do |value|
      raise Puppet::Error, "'source' file path must be fully qualified, not '#{value}'" unless Puppet::Util.absolute_path?(value)
    end
  end

  newproperty(:description) do
    desc "The item's description. Read-only"
    validate { |_val| raise Puppet::Error, 'description is read-only' }
  end

  newproperty(:item_title) do
    desc "The item's title. Read-only"
    validate { |_val| raise Puppet::Error, 'item_title is read-only' }
  end

  newproperty(:type) do
    desc "The item's type. Read-only"
    validate { |_val| raise Puppet::Error, 'type is read-only' }
  end

  newproperty(:last_save_date) do
    desc "The item's lastSaveDate. Read-only"
    validate { |_val| raise Puppet::Error, 'last_save_date is read-only' }
  end

  newproperty(:services, :array_matching => :all) do
    desc "The item's registered services"
    def insync?(is)
      is.sort == should.sort
    end
    validate do |value|
      raise ArgumentError, 'Services must be array of strings.' unless value.is_a?(String)
      raise ArgumentError, "Services cannot include ','." if value.include?(',')
      raise ArgumentError, "Services cannot include ' '." if value.include?(' ')
    end
  end
end
