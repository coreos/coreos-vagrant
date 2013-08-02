# CoreOS Vagrant

This repo provides a template Vagrantfile for CoreOS. To get a single
CoreOS node up and running do the following:

1) [Download and install Vagrant][vagrant] 1.2.3 or greater.

2) Clone this project and get it running!

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant
vagrant up
vagrant ssh
```

3) Get started [using CoreOS][using-coreos]

[vagrant]: http://downloads.vagrantup.com/
[using-coreos]: http://coreos.com/docs/using-coreos/

## Alternative Setup 

This allows you to run multiple without needing to clone the repo each time. 

1) [Download and install Vagrant][vagrant] 1.2.3 or greater.

2) Install the vagrant "box"

```
vagrant init coreos http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_vagrant.box
vagrant up
vagrant ssh
```

3) Get Started
