echo 'Stopping Docker Service'
systemctl stop docker.service 2>/dev/null

echo 'Removing Old Device'
mountpoint -q /var/lib/docker && umount /var/lib/docker
if [[ -n $(losetup /dev/loop0 2>/dev/null) ]]; then losetup -d /dev/loop0; fi

if [ ! -f $1 ]
  then
    echo 'Creating New Device Image'
    dd if=/dev/zero of=$1 bs=1 count=1 seek=$2
    losetup /dev/loop0 $1
    mkfs.btrfs -f /dev/loop0
  else
    echo 'Image Found. Creating Loop Device'
    truncate -s $2 $1
    losetup /dev/loop0 $1
fi

echo 'Mounting Device'
mkdir -p /var/lib/docker && mount -t btrfs /dev/loop0 /var/lib/docker

echo 'Starting Docker Service'
systemctl start docker.service
