Puppet::Type.newtype(:fme_user) do
  desc 'Puppet type that manages FME users'

  ensurable

  autorequire(:file) do
    Fme::Helper.settings_file
  end

  newparam(:name, :namevar => true) do
    desc 'User Name'
  end

  newproperty(:fullname) do
    desc 'User Full Name'
  end

  newproperty(:roles, :array_matching => :all) do
    desc 'Roles'
    def insync?(is)
      is.sort == should.sort
    end
    validate do |value|
      raise ArgumentError, 'Roles must be array of strings.' unless value.is_a?(String)
      raise ArgumentError, "Roles cannot include ','." if value.include?(',')
      raise ArgumentError, "Roles cannot include ' '." if value.include?(' ')
    end
  end

  newparam(:password) do
    desc "The User's password"
  end
end
