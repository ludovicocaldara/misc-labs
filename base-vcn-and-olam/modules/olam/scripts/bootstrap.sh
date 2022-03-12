#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

yum install -y python-oci-cli
systemctl enable ocid.service
systemctl start ocid.service
systemctl status ocid.service
