Puppet::Type.newtype(:fme_repository) do
  desc 'Puppet type that manages FME repositories'

  ensurable

  autorequire(:file) do
    Fme::Helper.settings_file
  end

  newparam(:name, :namevar => true) do
    desc 'Name of the repository'
  end

  newproperty(:description) do
    desc 'Description of the repository'
  end
end
