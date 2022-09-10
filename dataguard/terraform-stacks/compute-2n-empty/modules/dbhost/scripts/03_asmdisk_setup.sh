#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

####################################################
# This script:
# * Adds the group asmadmin (required for the workingcopy)
# * Partition the attached ASM disk
# * Sets udev persistent naming for the ASM disk


# to avoid empty variables
set -u 
# debugging output for terraform deployment
set -x

####################################################
# add group asmadmin and affect it to oracle
# (oracle user should be there already)
groupadd asmadmin
usermod -a -G asmadmin oracle


####################################################
# Partition the ASM disk
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

####################################################
# set udev persistent naming for the disk (same principle of RAC Attack)
scsiid=`/usr/lib/udev/scsi_id -g -u -d $${device}1`
echo "KERNEL==\"sd?1\", SUBSYSTEM==\"block\", PROGRAM==\"/usr/lib/udev/scsi_id -g -u -d /dev/\$parent\", RESULT==\"$scsiid\", SYMLINK+=\"oracleasm/asm-disk1\", OWNER=\"oracle\", GROUP=\"asmadmin\", MODE=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules

/sbin/partprobe $${device}1
sleep 2
/sbin/udevadm control --reload-rules
sleep 2
/sbin/partprobe $${device}1
sleep 2
/sbin/udevadm control --reload-rules

