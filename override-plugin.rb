# -*- mode: ruby -*-
# # vi: set ft=ruby :

# NOTE: This monkey-patching of the coreos guest plugin is a terrible
# hack that needs to be removed once the upstream plugin works with
# alpha CoreOS images.

require 'ipaddr'
require Vagrant.source_root.join("plugins/guests/coreos/cap/configure_networks.rb")

UNIT = <<EOF
[Match]
Name=%s

[Network]
Address=%s
EOF

# Borrowed from http://stackoverflow.com/questions/1825928/netmask-to-cidr-in-ruby
IPAddr.class_eval do
  def to_cidr
    self.to_i.to_s(2).count("1")
  end
end

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|

            # Read network interface names
            interfaces = []
            comm.sudo("ifconfig | grep enp0 | cut -f1 -d:") do |_, result|
              interfaces = result.split("\n")
            end

            # Configure interfaces
            # FIXME: fix matching of interfaces with IP adresses
            networks.each do |network|
              iface_num = network[:interface].to_i
              iface_name = interfaces[iface_num]
              cidr = IPAddr.new('255.255.255.0').to_cidr
              address = "%s/%s" % [network[:ip], cidr]
              unit = UNIT % [iface_name, address]
              comm.sudo("echo '%s' > /etc/systemd/network/%d-%s.network" % [unit, 10*iface_num, iface_name])

              #TODO(bcwaldon): The following sed command is racy with the unit that initially
              # populates /etc/environment. This line should be reenabled once that race is fixed.
              #comm.sudo("sed -i -e '/^COREOS_PUBLIC_IPV4=/d' -e '/^COREOS_PRIVATE_IPV4=/d' '/etc/environment'")

              comm.sudo("echo 'COREOS_PUBLIC_IPV4=#{network[:ip]}' >> /etc/environment")
              comm.sudo("echo 'COREOS_PRIVATE_IPV4=#{network[:ip]}' >> /etc/environment")
            end

            # This loads all of our network units we just created
            comm.sudo("systemctl restart systemd-networkd")

          end

        end
      end

      class ChangeHostName
        def self.change_host_name(machine, name)
            # do nothing!
        end
      end
    end
  end
end
