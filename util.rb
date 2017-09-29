
def get_provider
  # Look for "--provider foo"
  provider_index = ARGV.index('--provider')
  if (provider_index && ARGV[provider_index + 1])
     return ARGV[provider_index + 1]
  end

  # Look for "--provider=foo"
  for i in 1 ... ARGV.length
    if ARGV[i].include?('--provider=')
      return ARGV[i].sub('--provider=', '')
    end
  end

  # Note: The assumption of the default provider
  # being VirtualBox is predecated on the order
  # of the config.vm.provider calls in Vagrantfile
  return ENV['VAGRANT_DEFAULT_PROVIDER'] || 'virtualbox'
end

$provider = get_provider().to_sym

class VagrantPlugins::ProviderVirtualBox::Action::SetName
  alias_method :original_call, :call
  def call(env)
    machine = env[:machine]
    driver = machine.provider.driver
    uuid = driver.instance_eval { @uuid }
    ui = env[:ui]

    controller_name="SATA Controller"

    vm_info = driver.execute("showvminfo", uuid)
    controller_already_exists = vm_info.match("Storage Controller Name.*#{controller_name}")

    if controller_already_exists
      ui.info "already has the #{controller_name} hdd controller, skipping creation/add"
    else
      ui.info "creating #{controller_name} hdd controller"
      driver.execute(
        'storagectl',
        uuid,
        '--name', "#{controller_name}",
        '--add', 'sata',
        '--controller', 'IntelAHCI')
    end

    original_call(env)
  end
end

# Add persistent storage volumes
def attach_volumes(node, num_volumes, volume_size)

  if $provider == :virtualbox
    node.vm.provider :virtualbox do |v, override|
      (1..num_volumes).each do |disk|
        diskname = File.join(File.dirname(File.expand_path(__FILE__)), ".virtualbox", "#{node.vm.hostname}-#{disk}.vdi")
        unless File.exist?(diskname)
          v.customize ['createhd', '--filename', diskname, '--size', volume_size * 1024]
        end
        v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', disk, '--device', 0, '--type', 'hdd', '--medium', diskname]
      end
    end
  end

  if $provider == :vmware_fusion || $provider == "vmware_workstation"
    ["vmware_fusion", "vmware_workstation"].each do |vmware|
      node.vm.provider vmware do |v, override|

        vdiskmanager = '/Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager'
        if File.exist?(vdiskmanager)
          dir = File.join(File.dirname(File.expand_path(__FILE__)), ".vmware")
          unless File.directory?( dir )
            Dir.mkdir dir
          end

          (1..num_volumes).each do |disk|
            diskname = File.join(dir, "#{node.vm.hostname}-#{disk}.vmdk")
            unless File.exist?(diskname)
              `#{vdiskmanager} -c -s #{volume_size}GB -a lsilogic -t 1 #{diskname}`
            end

            v.vmx["scsi0:#{disk}.filename"] = diskname
            v.vmx["scsi0:#{disk}.present"] = 'TRUE'
            v.vmx["scsi0:#{disk}.redo"] = ''
          end
        end
      end
    end
  end

  if $provider == :parallels
    node.vm.provider :parallels do |v, override|
      (1..num_volumes).each do |disk|
        v.customize ['set', :id, '--device-add', 'hdd', '--size', volume_size * 1024]
      end
    end
  end

end
