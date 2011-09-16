#!/bin/bash
set -e

DIR=`basename $0`

if [ ! -f $DIR/debian.img ]; then
	echo "Downloading debian image..."
	wget http://ceph.newdream.net/qa/debian.img -O $DIR/debian.img
fi
touch $DIR/dummy_img
glance-upload --disk-format raw $DIR/dummy_img dummy_raw_img

sudo $DIR/nova.sh run_detached

echo "Waiting for image to become available..."
sudo chown ubuntu:ubuntu ~/openstack/nova/novarc
source ~/openstack/nova/novarc
while true; do
	if ( timeout 5 euca-describe-images | egrep -q "dummy_raw_img\)\s+available" ) then
		break
	fi
	sleep 2
done

echo "Creating volume..."
euca-create-volume -s 1 -z nova
echo "Waiting for volume to be available..."
while true; do
	if ( euca-describe-volumes | egrep -q "vol-00000001\s+1\s+nova\s+available" ) then
		break
	fi
	sleep 2
done

echo "Replacing blank image with real one..."
rbd rm volume-00000001
rbd import $DIR/debian.img volume-00000001
echo "Running instance based "
$DIR/boot-from-volume
vncviewer server: 0.0.0.0:5900 &
