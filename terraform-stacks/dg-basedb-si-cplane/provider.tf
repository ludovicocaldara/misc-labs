# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# ------------------------------------------------------------------------
# All the variables that are unique to your user / tenancy
# 
# If you fork from github, copy this file to "override.tf"
# so that your variables are not versioned publicly :-)
# override.tf is skipped by the .gitignore file
# ------------------------------------------------------------------------


# -------------------------
# Setup the OCI provider...
# -------------------------
provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint = var.fingerprint
  region = var.region
}

