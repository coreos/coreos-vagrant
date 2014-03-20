# -*- mode: ruby -*-
# # vi: set ft=ruby :

require_relative 'override-plugin.rb'

CLOUD_CONFIG_PATH = "./user-data"

Vagrant.configure("2") do |config|
  config.vm.box = "coreos"
  config.vm.box_url = "http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_vagrant.box"

  # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
  # config.vm.network "private_network", ip: "172.12.8.150"
  # config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']

  # Fix docker not being able to resolve private registry in VirtualBox
  config.vm.provider :virtualbox do |vb, override|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provider :vmware_fusion do |vb, override|
    override.vm.box_url = "http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_vagrant_vmware_fusion.box"
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  if File.exist?(CLOUD_CONFIG_PATH)
    config.vm.provision :file, :source => "#{CLOUD_CONFIG_PATH}", :destination => "/tmp/user-data"
    config.vm.provision :shell, :inline => "/usr/bin/coreos-cloudinit --from-file /tmp/user-data", :privileged => true
  end

end
