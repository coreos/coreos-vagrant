# CoreOS Vagrant

This repo provides a template Vagrantfile to create a CoreOS virtual machine using the VirtualBox software hypervisor.
After setup is complete you will have a single CoreOS virtual machine running on your local machine.

## Contact
IRC: #coreos on freenode.org

Mailing list: [coreos-dev](https://groups.google.com/forum/#!forum/coreos-dev)

## Streamlined setup

1) Install dependencies

* [VirtualBox][virtualbox] 4.3.10 or greater.
* [Vagrant][vagrant] 1.6.3 or greater.

2) Clone this project and get it running!

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant
```

3) Startup and SSH

There are two "providers" for Vagrant with slightly different instructions.
Follow one of the following two options:

**VirtualBox Provider**

The VirtualBox provider is the default Vagrant provider. Use this if you are unsure.

```
vagrant up
vagrant ssh
```

**VMware Provider**

The VMware provider is a commercial addon from Hashicorp that offers better stability and speed.
If you use this provider follow these instructions.

VMware Fusion:
```
vagrant up --provider vmware_fusion
vagrant ssh
```

VMware Workstation:
```
vagrant up --provider vmware_workstation
vagrant ssh
```

``vagrant up`` triggers vagrant to download the CoreOS image (if necessary) and (re)launch the instance

``vagrant ssh`` connects you to the virtual machine.
Configuration is stored in the directory so you can always return to this machine by executing vagrant ssh from the directory where the Vagrantfile was located.

4) Get started [using CoreOS][using-coreos]

[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/downloads.html
[using-coreos]: http://coreos.com/docs/using-coreos/

#### Shared Folder Setup

There is optional shared folder setup.
You can try it out by adding a section to your Vagrantfile like this.

```
config.vm.network "private_network", ip: "172.17.8.150"
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

#### Provisioning with Ignition (VirtualBox Provider (default))

When using the VirtualBox provider for Vagrant (the default), Ignition is used to provision the machine. This uses a special plugin that is
automatically installed when using the default Vagrantfile. The config options for the plugin are all prefixed with `config.ignition` and can
be found in this Vagrantfile or in the README of the [plugin](https://github.com/coreos/vagrant-ignition)

To get started, run `curl https://discovery.etcd.io/new\?size\=X`, where `X` is the number of servers in your cluster (if a size is not provided,
the default of 3 will be used). Then, replace `<token>` in the `cl.conf` file with the generated token from the curl command. More configuration may be added if necessary. Then, use config transpiler to write the Ignition config
to config.ign by running `ct --platform=vagrant-virtualbox < cl.conf > config.ign`. To see all available configuration options, check out
the [Container Linux Configuration Specification][clspec] as well as the [Container Linux Config Transpiler Getting Started Documentation][ignition].
There is also a basic Ignition file provided based on the Container Linux config that is included. To use that instead (not recommended),
copy `config.ign.sample` to `config.ign` and make any necessary modifications. Check out the [Ignition Getting Started documentation][ignition] 
to learn about the available features.

[ignition]: https://github.com/coreos/docs/blob/master/os/provisioning.md
[clspec]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/configuration.md

#### Provisioning with user-data (VMWare provider)

When using the VMWare provider for Vagrant, the Vagrantfile will provision your CoreOS VM(s)
with [coreos-cloudinit][coreos-cloudinit] if a `user-data` file is found in the project directory. coreos-cloudinit simplifies the
provisioning process through the use of a script or cloud-config document.

To get started, copy `user-data.sample` to `user-data` and make any necessary modifications.
Check out the [coreos-cloudinit documentation][coreos-cloudinit] to learn about the available features.

[coreos-cloudinit]: https://github.com/coreos/coreos-cloudinit

#### Configuration

The Vagrantfile will parse a `config.rb` file containing a set of options used to configure your CoreOS cluster.
See `config.rb.sample` for more information.

## Cluster Setup

Launching a CoreOS cluster on Vagrant is as simple as configuring `$num_instances` in a `config.rb` file to 3 (or more!) and running `vagrant up`.
If using the VirtualBox provider (default), copy the make sure to create a `config.ign` as described above so that the machines can be configured with
etcd and flanneld correctly. Also, make sure to provide a fresh discovery URL in your `config.ign` file to bootstrap etcd in your cluster.
If you are using the VMWare provider, make sure you provide a fresh discovery URL in your `user-data` if you wish to bootstrap etcd in your cluster.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS. You can do this by running
```
vagrant box update
```


## Docker Forwarding

By setting the `$expose_docker_tcp` configuration value you can forward a local TCP port to docker on
each CoreOS machine that you launch. The first machine will be available on the port that you specify
and each additional machine will increment the port by 1.

Follow the [Enable Remote API instructions][coreos-enabling-port-forwarding] to get the CoreOS VM setup to work with port forwarding.

[coreos-enabling-port-forwarding]: https://coreos.com/docs/launching-containers/building/customizing-docker/#enable-the-remote-api-on-a-new-socket

Then you can then use the `docker` command from your local shell by setting `DOCKER_HOST`:

    export DOCKER_HOST=tcp://localhost:2375

## Troubleshooting
If vagrant fails to run successfully, first make sure that the latest version of the coreos-vagrant project has been downloaded, then run
`vagrant destroy -f` to remove old machines, `vagrant box update` to update the OS box, and `vagrant plugin update vagrant-ignition` to
update the ignition plugin. If the problems persist after that, please report bugs at https://issues.coreos.com.
