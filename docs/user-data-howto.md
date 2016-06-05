# CoreOS user-data tips

To apply these behaviors, change / add following lines to you user-data.
Don't forget to apply user-data on your instance or during its creation.

```sh
coreos-cloudinit --from-file  /var/lib/coreos-vagrant/vagrantfile-user-data
```

### Change toolbox docker image

```yaml
write_files:
- path: "/home/core/.toolboxrc"
  owner: core
  content: |-
    TOOLBOX_DOCKER_IMAGE=ubuntu
    TOOLBOX_DOCKER_TAG=14.04

```

### add a proxy to your docker configuration

#### under units

```yaml 
  - name: docker.service
    drop-ins:
    - name: 20-http-proxy.conf
      content: |
        [Service]
        Environment="HTTP_PROXY=http://yourproxy:port" "HTTPS_PROXY=http://yourproxy:port" "http-proxy=http://yourproxy:port" "https-proxy=http://yourproxy:port"    "NO_PROXY=localhost,127.0.0.0/8,172.17.0.0/16,.sock,yourproxy,/var/run/docker.sock"
    command: restart
```

### start fleet daemon


#### under coreos

```yaml
  fleet:
    etcd-servers: http://$private_ipv4:2379
    public-ip: "$private_ipv4"
```

#### under units

```yaml 
  - name: fleet.service
    command: start
```

### Add simple flannel

#### under coreos

```yaml
  flannel:
    interface: "$public_ipv4"
```

#### under units

```yaml
  - name: flanneld.service
    drop-ins:
    - name: 50-network-config.conf
      content: |
        [Service]
        ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
    command: start
    
```
### Add simple etcd for 3 instances

this etcd configuration works for 3 instances with etcd2, no need internet to discover anything.
keyword : howto disable discovery

#### under config.rb

comment 'token = open($new_discovery_url).read'

#### under units

```yaml
  - name: etcd.service
    command: start
    content: |
      Description=etcd 2.0
      After=docker.service
      Conflicts=etcd.service

      [Service]
      User=etcd
      Type=notify
      EnvironmentFile=/etc/environment
      TimeoutStartSec=0
      SyslogIdentifier=writer_process
      Environment=ETCD_DATA_DIR=/var/lib/etcd2
      Environment=ETCD_NAME=%m
      ExecStart=/bin/bash -c "/usr/bin/etcd2 \
        -name %H \
        -listen-client-urls http://0.0.0.0:2379 \
        -advertise-client-urls http://$COREOS_PRIVATE_IPV4:2379 \
        -listen-peer-urls http://0.0.0.0:2380 \
        -initial-advertise-peer-urls http://$COREOS_PRIVATE_IPV4:2380 \
        -initial-cluster core-01=http://172.17.8.101:2380,core-02=http://172.17.8.102:2380,core-03=http://172.17.8.103:2380\
        -initial-cluster-state new"
      Restart=always
      RestartSec=10s
      LimitNOFILE=40000
      TimeoutStartSec=0



      [Install]
      WantedBy=multi-user.target

      [X-Fleet]
      Conflicts=etcd*
```


