#!/bin/bash

DIR=`dirname $0`

if [ ! -f $DIR/previous_packages.txt ]; then
	echo "No previous_packages.txt so we can't tell what to uninstall!"
	exit 1
fi
# We assume that we did not remove any packages
sudo dpkg --get-selections > $DIR/current_packages.txt
NEW_PKGS=`diff -u previous_packages.txt current_packages.txt | grep '^+' | cut -f 1 | cut -c 2- | tr '\n' ' '`
sudo apt-get remove $NEW_PKGS || echo "failed to remove packages" && exit 1
sudo rm -f /etc/ceph/ceph.conf
sudo rm -f /etc/apt/sources.list.d/ceph.list
sudo rm -rf ~/ceph_logs 
sudo rm -rf ~/openstack
rm -f $DIR/debian.img
rm -rf $DIR/qemu-kvm
# remove custom qemu
sudo rm /usr/bin/qemu-system-x86_64
