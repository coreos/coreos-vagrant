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

3) Run some commands on CoreOS:

Set and retrieve a key with [etcd][etcd]:

```
curl -L http://127.0.0.1:4001/v1/keys/message -d value="Hello world"
curl -L http://127.0.0.1:4001/v1/keys/message
```

Try out an Ubuntu container with [Docker guide][docker]:

```
docker run ubuntu /bin/echo hello world
docker run -i -t ubuntu /bin/bash
```

[vagrant]: http://downloads.vagrantup.com/
[docker]: http://www.docker.io/gettingstarted/#anchor-1
[etcd]: https://github.com/coreos/etcd
