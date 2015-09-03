# CoreOS Vagrant

This repo provides a template Vagrantfile to create a CoreOS virtual machine using the VirtualBox software hypervisor.
After setup is complete you will have a single CoreOS virtual machine running on your local machine.

## Streamlined setup

1) Install dependencies

* [VirtualBox][virtualbox] 4.3.10 or greater.
* [Vagrant][vagrant] 1.6 or greater.
* ([GitHub][GitHub Desktop])
* ([PuTTY][PuTTY]) 0.64 or greater.
* ([Cygwin][cwgwin]) 
* ([apple][bonjour])

2) Clone this project and get it running!

```
git clone https://github.com/jschott2/coreos-vagrant/
cd coreos-vagrant
```

3) Startup and SSH

The Windows 7 "provider" for Vagrant is VirtualBox:

**VirtualBox Provider**

The VirtualBox provider is the default Vagrant provider. Use this if you are unsure.

```
vagrant up
```

``vagrant up`` triggers vagrant to download the CoreOS image (if necessary) and (re)launch the instance

The SSH client used in this scenario is PuTTY which provides a client interface.  PuTTY is a Windows focused tool.
You can set up command line launching but it does not seem to be high value over launching from taskbar. 
Configuration of the PuTTY session includes transforming the insecure_private_key to a PuTTY format; importing that key into the session; defining the IP; defining the port; and giving the session a name so it can be saved for loading later. 
Once saved the configuration is stored in PuTTY so you can always return to this machine from PuTTY or right-click the PuTTY Configuration icon on the task bar and select a recent session.

4) Get started [using CoreOS][using-coreos]

[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/downloads.html
[using-coreos]: http://coreos.com/docs/using-coreos/
[GitHub][GitHub Desktop]: https://desktop.github.com/
[PuTTY][PuTTY]: http://www.putty.org/
[Cygwin][cwgwin]: https://cygwin.com/install.html  (see: http://www.howtogeek.com/175008/the-non-beginners-guide-to-syncing-data-with-rsync/)
[apple][bonjour]: https://support.apple.com/kb/DL999?locale=en_US

#### Shared Folder Setup

There is optional shared folder setup.
You can try it out by adding a section to your Vagrantfile like this.

```
config.vm.synced_folder "./shared", "/home/core/share2/", type: "rsync"
config.vm.synced_folder "./shared", "/home/core/share/", type: "rsync"
```

After a 'vagrant reload'.

The Guest folders will be refreshed from the Host shared folders.

Windows 7 also requires using rsync that was retrieved in Cygwin install.  There are utilities that are provided to assist in setting up users on the guest with the insecure_private_key SSH keys and the rsync command to synchronize to the host.
Find user_up.sh in the shared folder.
Find rsyncvmshare.bat in the coreos-vagrant folder.

Copy helper.rb.jschott2.endstate.clean to 'C:\HashiCorp\Vagrant\embedded\gems\gems\vagrant-1.7.4\plugins\synced_folders\rsync\' 
Or you can modify the helper.rb file in that directory adding 'hostpath = "/cygdrive" + hostpath' as shown below.
        if Vagrant::Util::Platform.windows?
          # rsync for Windows expects cygwin style paths, always.
          hostpath = Vagrant::Util::Platform.cygwin_path(hostpath)
           hostpath = "/cygdrive" + hostpath
        end

#### Provisioning with user-data

The Vagrantfile will provision your CoreOS VM(s) with [coreos-cloudinit][coreos-cloudinit] if a `user-data` file is found in the project directory.
coreos-cloudinit simplifies the provisioning process through the use of a script or cloud-config document.

To get started, copy `user-data.jschott2.endstate` to `user-data` and make any necessary modifications.
Check out the [coreos-cloudinit documentation][coreos-cloudinit] to learn about the available features.

[coreos-cloudinit]: https://github.com/coreos/coreos-cloudinit

#### Configuration

The Vagrantfile will parse a `config.rb` file containing a set of options used to configure your CoreOS cluster.
See `config.rb.sample` for more information.  
Copy 'config.rb.jschott2.endstate' to 'config.rb'

## Cluster Setup

Launching a CoreOS cluster on Vagrant is as simple as configuring `$num_instances` in a `config.rb` file to 3 (or more!) and running `vagrant up`.
Make sure you provide a fresh discovery URL in your `user-data` if you wish to bootstrap etcd in your cluster.

## Cluster / VM destroy 

Cygwin Specific Instructions
When you issue a 'vagrant destroy' command and then desire to refresh the environment you need to mofify the 'known_hosts' file.  This will remove the old SSH fingerprints for the cluster machine names and allow you to rsync from the Guest to the Host.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS.
Simply remove the old box file and vagrant will download the latest one the next time you `vagrant up`.

```
vagrant box remove coreos --provider virtualbox
```

## Docker Forwarding
## Not yet tested by this author.
By setting the `$expose_docker_tcp` configuration value you can forward a local TCP port to docker on
each CoreOS machine that you launch. The first machine will be available on the port that you specify
and each additional machine will increment the port by 1.

Follow the [Enable Remote API instructions][coreos-enabling-port-forwarding] to get the CoreOS VM setup to work with port forwarding.

[coreos-enabling-port-forwarding]: https://coreos.com/docs/launching-containers/building/customizing-docker/#enable-the-remote-api-on-a-new-socket

Then you can then use the `docker` command from your local shell by setting `DOCKER_HOST`:

    export DOCKER_HOST=tcp://localhost:2375
