require 'puppet/provider'

class Puppet::Provider::Fme < Puppet::Provider
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
end
