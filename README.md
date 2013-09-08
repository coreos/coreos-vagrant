# CoreOS Vagrant

This repo provides a template Vagrantfile to create a CoreOS virtual machine using the Virtualbox software hypervisor.
After setup is complete you will have a single CoreOS virtual machine running on your local machine.

## Streamlined setup

1) Install dependencies

* [Virtualbox][virtualbox] 4.0 or greater.
* [Vagrant][vagrant] 1.3.1 or greater.

2) Clone this project and get it running!

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant
# cd vmware if you have vmware + vagrant
vagrant up
vagrant ssh
```

``vagrant up`` triggers vagrant to download the CoreOS image (if necessary) and (re)launch the 
instance

``vagrant ssh`` connects you to the virtual machine. Configuration is stored in the 
directory so you can always return to this machine by executing vagrant ssh from the directory
where the Vagrantfile was located


3) Get started [using CoreOS][using-coreos]

[virtualbox]: https://www.virtualbox.org/
[vagrant]: http://downloads.vagrantup.com/
[using-coreos]: http://coreos.com/docs/using-coreos/



## Alternative Setup 

This allows you to run multiple instances without needing to clone the repo each time. It will create a 
Vagrantfile in your current directory and so, you will be able to (re)connect to the virtual 
machine by returning to this directory and running vagrant ssh.

1) [Download and install Vagrant][vagrant] 1.2.3 or greater.

2) Install the vagrant "box" and get it running

```
vagrant init coreos http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_vagrant.box
vagrant up
vagrant ssh
```

