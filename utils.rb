
# Install required plugins if not present.
required_plugins = ["vagrant-triggers", "vagrant-gatling-rsync", "vagrant-proxyconf"]
required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end

module Utils
    # UI Object for console interactions.
    @ui = Vagrant::UI::Colored.new

    # Determine if we are on Windows host or not.
    @is_windows = Vagrant::Util::Platform.windows?

    # Determine paths.
    $vagrant_root = File.dirname(__FILE__)  # Vagrantfile location
    if @is_windows
      @vagrant_mount_point = `cygpath #{$vagrant_root}`.strip! # Remove trailing \n
      @vagrant_mount_point = @vagrant_mount_point.gsub(/\/cygdrive/, '')  # Remove '/cygdrive' prefix
    else
      @vagrant_mount_point = $vagrant_root
    end

    $vagrant_folder_name = File.basename($vagrant_root)  # Folder name only. Used as the SMB share name.

    # Use vagrant.yml for local VM configuration overrides.
    require 'yaml'
    if !File.exist?($vagrant_root + '/sync-folders.yml')
      @ui.error 'Configuration file not found! Please copy vagrant.yml.dist to vagrant.yml and try again.'
      exit
    end
    @vconfig = YAML::load_file($vagrant_root + '/sync-folders.yml')

    if @is_windows
      require 'win32ole'
      # Determine if Vagrant was launched from the elevated command prompt.
      @running_as_admin = ((`reg query HKU\\S-1-5-19 2>&1` =~ /ERROR/).nil? && @is_windows)
      
      # Run command in an elevated shell.
      def windows_elevated_shell(args)
        command = 'cmd.exe'
        args = "/C #{args} || timeout 10"
        shell = WIN32OLE.new('Shell.Application')
        shell.ShellExecute(command, args, nil, 'runas')
      end

      # Method to create the user and SMB network share on Windows.
      def windows_net_share(share_name, path)
        # Add the vagrant user if it does not exist.
        smb_username = @vconfig['synced_folders']['smb_username']
        smb_password = @vconfig['synced_folders']['smb_password']
        
        command_user = "net user #{smb_username} || ( net user #{smb_username} #{smb_password} /add && WMIC USERACCOUNT WHERE \"Name='vagrant'\" SET PasswordExpires=FALSE )"
        @ui.info "Adding vagrant user"
        puts command_user
        windows_elevated_shell command_user

        # Add the SMB share if it does not exist.
        command_share = "net share #{share_name} || net share #{share_name}=#{path} /grant:#{smb_username},FULL"
        @ui.info "Adding vagrant SMB share"
        puts command_share
        windows_elevated_shell command_share

        # Set folder permissions.
        command_permissions = "icacls #{path} /grant #{smb_username}:(OI)(CI)M"
        @ui.info "Setting folder permissions"
        puts command_permissions
        windows_elevated_shell command_permissions
      end

      # Method to remove the user and SMB network share on Windows.
      def windows_net_share_remove(share_name)
        smb_username = @vconfig['synced_folders']['smb_username']

        command_user = "net user #{smb_username} /delete || echo 'User #{smb_username} does not exist' && timeout 10"
        windows_elevated_shell command_user

        command_share = "net share #{share_name} /delete || echo 'Share #{share_name} does not exist' && timeout 10"
        windows_elevated_shell command_share
      end
    else
      # Determine if Vagrant was launched with sudo (as root).
      running_as_root = (Process.uid == 0)
    end

    # Vagrant should NOT be run as root/admin.
    if running_as_root
    # || @running_as_admin
      @ui.error "Vagrant should be run as a regular user to avoid issues."
      exit
    end

    def set_share(config, ip)
        # Determine if we are on Windows host or not.
        @is_windows = Vagrant::Util::Platform.windows?
       
       
     ####################################################################
     ## Synced folders configuration ##
      box_ip = ip  # e.g. 192.168.10.10
      $host_ip = "10.0.2.2" # box_ip.gsub(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/, '\1.\2.\3.1')  # e.g. 192.168.10.1
      
          
     
      synced_folders = @vconfig['synced_folders']
      # nfs: Better performance on Mac
      if synced_folders['type'] == "nfs"  && !@is_windows
        @ui.success "Using nfs synced folder option"
        config.vm.synced_folder $vagrant_root, @vagrant_mount_point,
          type: "nfs",
          mount_options: ["nolock", "vers=3", "tcp"]
        config.nfs.map_uid = Process.uid
        config.nfs.map_gid = Process.gid
      # nfs2: Optimized NFS settings for even better performance on Mac, experimental
      elsif ( synced_folders['type'] == "nfs2" || synced_folders['type'] == "default" )  && !@is_windows
        @ui.success "Using nfs2 synced folder option"
        config.vm.synced_folder $vagrant_root, @vagrant_mount_point,
          type: "nfs",
          mount_options: ["nolock", "noacl", "nocto", "noatime", "nodiratime", "vers=3", "tcp", "actimeo=2"]
        config.nfs.map_uid = Process.uid
        config.nfs.map_gid = Process.gid
      # smb: Better performance on Windows. Requires Vagrant to be run with admin privileges.
      elsif synced_folders['type'] == "smb" && @is_windows
        @ui.success "Using smb synced folder option"
        config.vm.synced_folder $vagrant_root, @vagrant_mount_point,
          type: "smb",
          smb_username: synced_folders['smb_username'],
          smb_password: synced_folders['smb_password']
      # smb2: Better performance on Windows. Does not require running vagrant as admin.
      elsif ( synced_folders['type'] == "smb2" || synced_folders['type'] == "default" ) && @is_windows
        @ui.success "Using smb2 synced folder option"

        if @vconfig['synced_folders']['smb2_auto']
          # Create the share before 'up'.
          config.trigger.before :up, :stdout => true, :force => true do
            info 'Setting up SMB user and share'
            Utils.windows_net_share $vagrant_folder_name, $vagrant_root
          end

          # Remove the share after 'halt'.
          config.trigger.after :destroy, :stdout => true, :force => true do
            info 'Removing SMB user and share'
            Utils.windows_net_share_remove $vagrant_folder_name
          end
        end

        # Mount the share in boot2docker.
        config.vm.provision "shell", run: "always" do |s|
            @ui.info "host ip: " + $host_ip
          s.inline = <<-SCRIPT
            mkdir -p vagrant $2
            mount -t cifs -o uid=`id -u docker`,gid=`id -g docker`,noperm,username=$3,domain=$7,vers=$7,pass=$4,dir_mode=0777,file_mode=0777 //$5/$1 $2
          SCRIPT
          s.args = "#{$vagrant_folder_name} #{@vagrant_mount_point} #{@vconfig['synced_folders']['smb_username']} #{@vconfig['synced_folders']['smb_password']} #{$host_ip} #{@vconfig['synced_folders']['smb_domain']} #{@vconfig['synced_folders']['smb_vers']}"
        end
      # rsync: the best performance, cross-platform platform, one-way only.
      elsif synced_folders['type'] == "rsync"
        @ui.success "Using rsync synced folder option"

        # Construct and array for rsync_exclude
        rsync_exclude = []
        unless synced_folders['rsync_exclude'].nil?
          for item in synced_folders['rsync_exclude'] do
            rsync_exclude.push(item)
          end
        end

        # Only sync explicitly listed folders.
        if synced_folders['rsync_folders'].nil?
          @ui.error "ERROR: 'folders' list cannot be empty when using 'rsync' sync type. Please check your vagrant.yml file."
          exit
        else
          for synced_folder in synced_folders['rsync_folders'] do
            config.vm.synced_folder "#{$vagrant_root}/#{synced_folder}", "#{@vagrant_mount_point}/#{synced_folder}",
              type: "rsync",
              rsync__exclude: rsync_exclude,
              rsync__args: ["--archive", "--delete", "--compress", "--whole-file"]
          end
        end
        # Configure vagrant-gatling-rsync
        config.gatling.rsync_on_startup = false
        config.gatling.latency = synced_folders['rsync_latency']
        config.gatling.time_format = "%H:%M:%S"

        # Launch gatling-rsync-auto in the background
        if synced_folders['rsync_auto'] && !@is_windows
          [:up, :reload, :resume].each do |trigger|
            config.trigger.after trigger do
              success "Starting background rsync-auto process..."
              info "Run 'tail -f #{$vagrant_root}/rsync.log' to see rsync-auto logs."
              # Kill the old sync process
              `kill $(pgrep -f rsync-auto) > /dev/null 2>&1 || true`
              # Start a new sync process in background
              `vagrant gatling-rsync-auto >> rsync.log &`
            end
          end
          [:halt, :suspend, :destroy].each do |trigger|
            config.trigger.before trigger do
              # Kill rsync-auto process
              success "Stopping background rsync-auto process..."
              `kill $(pgrep -f rsync-auto) > /dev/null 2>&1 || true`
              `rm -f rsync.log`
            end
          end
        end
      # vboxsf: reliable, cross-platform and terribly slow performance
      elsif synced_folders['type'] == "vboxsf"
        @ui.warn "WARNING: Using the SLOWEST folder sync option (vboxsf)"
        config.vm.synced_folder $vagrant_root, @vagrant_mount_point
      # Warn if neither synced_folder not individual_mounts is enabled
      elsif synced_folders['individual_mounts'].nil?
        @ui.error "ERROR: Synced folders not enabled or misconfigured. The VM will not have access to files on the host."
      end

      # Individual mounts
      unless synced_folders['individual_mounts'].nil?
        @ui.success "Using individual_mounts synced folder option"
        for synced_folder in synced_folders['individual_mounts'] do
          if synced_folder['type'] == 'vboxsf'
            config.vm.synced_folder synced_folder['location'], synced_folder['mount'],
              mount_options: [synced_folder['options']]
          elsif synced_folder['type'] == 'nfs'
            config.vm.synced_folder synced_folder['location'], synced_folder['mount'],
              type: "nfs",
              mount_options: [synced_folder['options']]
          end
        end
      end

      # Make host home directory available to containers in /.home
    #  if File.directory?(File.expand_path("~"))
     #   config.vm.synced_folder "~", "/.home"
      #end

      # Make host SSH keys available to containers in /.ssh (legacy, TO BE REMOVED soon)
      #if File.directory?(File.expand_path("~/.ssh"))
       # config.vm.synced_folder "~/.ssh", "/.ssh"
      #end

      ######################################################################
    end
end
    