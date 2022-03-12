#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

#########################################
# This script:
# * Sets up the EPEL repo
# * Install some required packages
# * Stops and disable the firewall

###########################
# Setup the EPEL repo
regionId=$(curl -s http://169.254.169.254/opc/v1/instance/ | grep regionIdentifier | awk -F: '{print $2}' | awk -F'"' '{print $2}')

wget https://swiftobjectstorage.$regionId.oraclecloud.com/v1/dbaaspatchstore/DBaaSOSPatches/oci_dbaas_ol7repo -O /tmp/oci_dbaas_ol7repo
wget https://swiftobjectstorage.$regionId.oraclecloud.com/v1/dbaaspatchstore/DBaaSOSPatches/versionlock_ol7.list -O /tmp/versionlock.list

mv /tmp/oci_dbaas_ol7repo /etc/yum.repos.d/ol7.repo
mv /tmp/versionlock.list  /etc/yum/pluginconf.d/versionlock.list

cat > /etc/yum.repos.d/ol8.epel.repo <<EOF
[ol8_epel]
name=Oracle Linux $releasever Latest ($basearch)
baseurl=https://yum.oracle.com/repo/OracleLinux/OL8/developer/EPEL/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF


###########################
# install git, rlwrap and the database preinstall package
dnf install -y dnf-utils zip unzip git rlwrap tar gzip
dnf install -y podman podman-docker buildah skopeo ansible


###########################
# stop the firewall.
systemctl stop firewalld
systemctl disable firewalld

###########################
# disable SELinux
sed -i -e "s|SELINUX=enforcing|SELINUX=permissive|g" /etc/selinux/config
setenforce permissive

###########################
# add oracle container registry
sed -i -e "s|'container-registry.oracle.com', 'docker.io'|'docker.io', 'container-registry.oracle.com'|g" /etc/containers/registries.conf

