Puppet::Type.newtype(:fme_service) do
  desc 'Puppet type that manages FME services'

  ensurable do
    newvalue(:present) do
      raise Puppet::Error, 'Creation of fme_service resources not implemented'
    end

    newvalue(:absent) do
      raise Puppet::Error, 'Deletion of fme_service resources not implemented'
    end

    defaultto(:present)
  end

  autorequire(:file) do
    Fme::Helper.settings_file
  end

  newparam(:name, :namevar => true) do
    desc 'Unique name of the service'
  end

  newproperty(:display_name) do
    desc 'Friendly name of the service'
  end

  newproperty(:description) do
    desc 'Human readable description of the service'
  end

  newproperty(:enabled) do
  end

  newproperty(:url) do
    desc 'The URL pattern of the service'
  end
end
