#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

# to avoid empty variables
set -u 
# debugging output for terraform deployment
set -x

###########################################################
# Disk partitioning
#
# the variables ipv4, port, attachment_type and iqn are replaced by the terraform templating engine
deviceByPath=/dev/disk/by-path/ip-${ipv4}:${port}-${attachment_type}-${iqn}-lun-1 
device=$(readlink -f $deviceByPath)

parted -s -a optimal $device mklabel gpt -- mkpart primary 2048s 100%
sleep 1

###########################################################
# LVM setup
# notice here double-dollar: it's to escape the dollar for the terraform templating engine
pvcreate $${device}1
vgcreate VolGroupContainers $${device}1
lvcreate -y -l 100%FREE -n LogVolContainers VolGroupContainers
# Make XFS
mkfs.xfs -f /dev/VolGroupContainers/LogVolContainers
# Set fstab
UUID=`blkid -s UUID -o value /dev/VolGroupContainers/LogVolContainers`
mkdir -p /var/lib/containers

# echoing UUID to force variable expansion: the "set -u" makes it exit with error if the variable is not there
echo $UUID

###########################################################
# add to fstab and mount
cat >> /etc/fstab <<EOF
UUID=$${UUID}  /var/lib/containers    xfs    defaults,noatime,_netdev      0      2
EOF
# Mount
mount /var/lib/containers

