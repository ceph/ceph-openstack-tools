#!/bin/bash
set -e

DIR=`basename $0`

sudo dpkg --get-selections > $DIR/previous_packages.txt

if [ ! -f /etc/apt/sources.list.d/ceph.list ]; then
	(cat <<EOF
deb http://ceph.newdream.net/debian-snapshot-amd64/master/ natty main
deb-src http://ceph.newdream.net/debian-snapshot-amd64/master/ natty main
EOF
) | sudo tee /etc/apt/sources.list.d/ceph.list
fi

sudo apt-get update
sudo apt-get install -y ceph librbd-dev libglib2.0-dev xvnc4viewer
# For running nova tests:
sudo apt-get install -y libxml2-dev libxslt1-dev swig
sudo cp $DIR/ceph.conf /etc/ceph/ceph.conf
mkdir -p ~/ceph_logs/dev/osd0 ~/ceph_logs/dev/mon.a ~/ceph_logs/dev/mon.b ~/ceph_logs/dev/mon.c ~/ceph_logs/out
sudo mkcephfs -a -c /etc/ceph/ceph.conf
sudo service ceph start
mkdir ~/openstack

$DIR/nova.sh install
git clone git://ceph.newdream.net/git/qemu-kvm.git $DIR/qemu-kvm
cd $DIR/qemu-kvm
./configure --enable-rbd --enable-system --enable-kvm --prefix=/usr --sysconfdir=/etc --enable-io-thread
make -j4
sudo make install

$DIR/nova.sh branch
