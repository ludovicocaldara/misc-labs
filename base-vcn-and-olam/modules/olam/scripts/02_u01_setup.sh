#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

#############################################################################
# This script
# * Sets password authentication fos sshd connections coming from the subnet
# * Sets opf@fppc password
# * Partition the attached disk, partition and mount it on /u01
#

# to avoid empty variables
set -u 
# debugging output for terraform deployment
set -x

###############################################################################
# enable SHH password authentication in the subnet only
# this is required for rhpctl remote commands without the need to set up ssh key authentication
# It stays key-only authentication outside of the subnet, so it is still secured from internet access
#sed -i /^PasswordAuthentication/d /etc/ssh/sshd_config
#cat <<EOF >> /etc/ssh/sshd_config
#PasswordAuthentication no
#Match address ${vcn_cidr}
#    PasswordAuthentication yes
#EOF
#systemctl reload sshd


###########################################################
# setting default password for opc@fppc
#echo "FPPll##123" | passwd --stdin opc


###########################################################
# Disk partitioning
#
# the variables ipv4, port, attachment_type and iqn are replaced by the terraform templating engine
deviceByPath=/dev/disk/by-path/ip-${ipv4}:${port}-${attachment_type}-${iqn}-lun-1 
device=$(readlink -e $deviceByPath)

# A few steps to add the iscsi volume in case the ocid.service omits the discover.
if [ $? -ne 0 ] ; then
  sudo iscsiadm -m node -o new -T ${iqn} -p ${ipv4}:${port}
  sleep 1
  sudo iscsiadm -m node -o update -T ${iqn} -n node.startup -v automatic
  sleep 1
  sudo iscsiadm -m node -T ${iqn} -p ${ipv4}:${port} -l
  sleep 2
fi

device=$(readlink -e $deviceByPath)
if [ $? -ne 0 ] ; then
  echo "Cannot add device through iscsiadm"
  exit 1
fi

parted -s -a optimal $device mklabel gpt -- mkpart primary 2048s 100%
sleep 1

###########################################################
# LVM setup
# notice here double-dollar: it's to escape the dollar for the terraform templating engine
pvcreate $${device}1
vgcreate VolGroupU01 $${device}1
lvcreate -y -l 100%FREE -n LogVolU01 VolGroupU01
# Make XFS
mkfs.xfs -f /dev/VolGroupU01/LogVolU01
# Set fstab
UUID=`blkid -s UUID -o value /dev/VolGroupU01/LogVolU01`
mkdir -p /u01

# echoing UUID to force variable expansion: the "set -u" makes it exit with error if the variable is not there
echo $UUID

###########################################################
# add to fstab and mount
cat >> /etc/fstab <<EOF
UUID=$${UUID}  /u01    xfs    defaults,noatime,_netdev      0      2
EOF
# Mount
mount /u01

