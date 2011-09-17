#!/bin/bash

DIR=`dirname $0`

if [ ! -f $DIR/previous_packages.txt ]; then
	echo "No previous_packages.txt so we can't tell what to uninstall!"
	exit 1
fi

# remove custom qemu files
sudo rm -f /usr/bin/qemu-system-x86_64
sudo rm -rf /usr/share/qemu
# We assume that we did not remove any packages
sudo dpkg --get-selections > $DIR/current_packages.txt
NEW_PKGS=`diff -u previous_packages.txt current_packages.txt | grep '^+[^+]' | cut -f 1 | cut -c 2- | tr '\n' ' '`
sudo apt-get remove $NEW_PKGS
sudo rm -f /etc/ceph/ceph.conf
sudo rm -f /etc/apt/sources.list.d/ceph.list
sudo rm -rf ~/ceph_logs 
sudo rm -rf ~/openstack
rm -rf $DIR/qemu-kvm
