#!/bin/bash
set -e

DIR=`pwd`

sudo dpkg --get-selections > previous_packages.txt

if [ ! -f /etc/apt/sources.list.d/ceph.list ]; then
	(cat <<EOF
deb http://ceph.newdream.net/debian-snapshot-amd64/master/ natty main
deb-src http://ceph.newdream.net/debian-snapshot-amd64/master/ natty main
EOF
) | sudo tee /etc/apt/sources.list.d/ceph.list
fi

sudo apt-get update
sudo apt-get install -y ceph librbd-dev libglib2.0-dev xvnc4viewer
sudo cp $DIR/ceph.conf /etc/ceph/ceph.conf
mkdir -p ~/ceph_logs/dev/osd0 ~/ceph_logs/dev/mon.a ~/ceph_logs/dev/mon.b ~/ceph_logs/dev/mon.c ~/ceph_logs/out
sudo mkcephfs -a -c /etc/ceph/ceph.conf
sudo service ceph start
mkdir ~/openstack

wget http://ceph.newdream.net/qa/debian.img
$DIR/nova.sh install
touch dummy_img
glance-upload --disk-format raw debian.img small_debian
git clone git://ceph.newdream.net/git/qemu-kvm.git
cd qemu-kvm
./configure --enable-rbd --enable-system --enable-kvm --prefix=/usr --sysconfdir=/etc --enable-io-thread
make -j4
sudo make install

$DIR/nova.sh branch
sudo $DIR/nova.sh run &

sudo chown ubuntu:ubuntu ~/openstack/nova/novarc
source ~/openstack/nova/novarc
while true; do
	if ( timeout 5 euca-describe-images | grep -q "small_debian\s+available" ) then
		break
	fi
done

echo "Creating volume..."
euca-create-volume -s 1 -z nova
while true; do
	if ( euca-describe-volumes | grep -q "vol-00000001.*available" ) then
		break
	fi
done

rbd rm volume-00000001
rbd import debian.img volume-00000001
$DIR/boot-from-volume
vncviewer server: 0.0.0.0:5900 &
