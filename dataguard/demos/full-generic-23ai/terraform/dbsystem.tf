//======== ADG 23ai, TF12 Compatible
terraform {
  required_providers {
    oci = {
     source = "oracle/oci"
     version = "6.30.0"
    }
  }
}
provider "oci" {
  region           = "${var.region}"
}
#*************************************
#             DB System
#*************************************
resource "oci_database_db_system" "adg_db_system" {
  count                   = var.members
  availability_domain     = data.oci_identity_availability_domain.ad.name
  compartment_id          = var.compartment_ocid
  cpu_core_count          = var.cpu_core_count
  data_storage_percentage = var.data_storage_percentage
  data_storage_size_in_gb = var.data_storage_size_in_gb
  database_edition        = var.db_edition
  db_home {
    database {
      admin_password = var.db_admin_password
      db_name        = var.lab_name
      pdb_name       = var.pdb_name
      db_unique_name = "${var.lab_name}_site${count.index}"
    }
    db_version     = var.db_version
    display_name = "${var.lab_name}${count.index}-23aiHome"
  }
  db_system_options {
    storage_management = var.storage_management
  }
  source = "NONE"
  subnet_id               = oci_core_subnets.lab_subnet.id
  ssh_public_keys         = [ var.ssh_public_key ]
  hostname                = "${var.lab_name}${count.index}-${var.resId}"
  license_model           = var.license_model
  node_count              = var.node_count
  display_name            = "${var.lab_name}${count.index}-${var.resId}"
}
