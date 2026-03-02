#!/bin/bash

regionId=$(curl -s http://169.254.169.254/opc/v1/instance/ | grep regionIdentifier | awk -F: '{print $2}' | awk -F'"' '{print $2}')

wget https://swiftobjectstorage.$regionId.oraclecloud.com/v1/dbaaspatchstore/DBaaSOSPatches/oci_dbaas_ol7repo -O /tmp/oci_dbaas_ol7repo
wget https://swiftobjectstorage.$regionId.oraclecloud.com/v1/dbaaspatchstore/DBaaSOSPatches/versionlock_ol7.list -O /tmp/versionlock.list

mv /tmp/oci_dbaas_ol7repo /etc/yum.repos.d/ol7.repo
mv /tmp/versionlock.list  /etc/yum/pluginconf.d/versionlock.list

cat > /etc/yum.repos.d/ol7.epel.repo <<EOF
[ol7_epel]
name=Oracle Linux $releasever Latest ($basearch)
baseurl=https://yum.oracle.com/repo/OracleLinux/OL7/developer_EPEL/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF

yum repolist
yum install -y git rlwrap jq
