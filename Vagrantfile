# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require_relative 'override-plugin.rb'

NUM_INSTANCES = (ENV['NUM_INSTANCES'].to_i > 0 && ENV['NUM_INSTANCES'].to_i) || [ Dir[".vagrant/machines/*"].count, 1 ].max

IP_CNET = ENV['IP_CNET'] || "172.17.8"
IP_BASE = (ENV['IP_BASE'].to_i > 0 && ENV['IP_BASE'].to_i) || 100
IP_INCR = (ENV['IP_INCR'].to_i > 0 && ENV['IP_INCR'].to_i) || 1

CORE_FOLDER = ENV['CORE_FOLDER']
HOST_FOLDER = ENV['HOST_FOLDER']

SERIAL = false

CLOUD_CONFIG_PATH = "./user-data"

Vagrant.configure("2") do |config|
  config.vm.box = "coreos-alpha"
  config.vm.box_url = "http://storage.core-os.net/coreos/amd64-usr/alpha/coreos_production_vagrant.box"

  config.vm.provider :vmware_fusion do |vb, override|
    override.vm.box_url = "http://storage.core-os.net/coreos/amd64-usr/alpha/coreos_production_vagrant_vmware_fusion.box"
  end

  # Fix docker not being able to resolve private registry in VirtualBox
  config.vm.provider :virtualbox do |vb, override|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  (1..NUM_INSTANCES).each do |i|
    config.vm.define vm_name = "core-%02d" % i do |config|
      config.vm.hostname = vm_name

      if SERIAL then
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
        FileUtils.touch(serialFile)

        config.vm.provider :vmware_fusion do |v, override|
          v.vmx["serial0.present"] = "TRUE"
          v.vmx["serial0.fileType"] = "file"
          v.vmx["serial0.fileName"] = serialFile
          v.vmx["serial0.tryNoRxLoss"] = "FALSE"
        end

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      ip = "#{IP_CNET}.#{IP_BASE+i*IP_INCR}"

      config.vm.network :private_network, ip: ip

      if CORE_FOLDER != nil and HOST_FOLDER != nil then
        config.vm.synced_folder "#{HOST_FOLDER}", "#{CORE_FOLDER}", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      end

      if File.exist?(CLOUD_CONFIG_PATH)
        config.vm.provision :file, :source => "#{CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      end

    end
  end
end
