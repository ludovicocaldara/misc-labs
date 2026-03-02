resource "oci_database_db_system" "adg_db_system" {
  count                   = var.members
  availability_domain     = data.oci_identity_availability_domain.ad.name
  compartment_id          = var.compartment_ocid
  subnet_id               = oci_core_subnet.lab_subnet.id
  shape                   = var.db_shape
  ssh_public_keys         = [var.ssh_public_key]
  hostname                = "${var.lab_name}${count.index}"
  display_name            = "${var.lab_name}${count.index}"
  license_model           = var.license_model
  node_count              = var.node_count
  cpu_core_count          = var.cpu_core_count
  data_storage_percentage = var.data_storage_percentage
  data_storage_size_in_gb = var.data_storage_size_in_gb
  database_edition        = var.db_edition
  source                  = "NONE"

  db_home {
    display_name = "${var.lab_name}${count.index}-23aiHome"
    db_version   = var.db_version

    database {
      admin_password = var.db_admin_password
      db_name        = var.lab_name
      pdb_name       = var.pdb_name
      db_unique_name = "${var.lab_name}_site${count.index + 1}"
    }
  }

  db_system_options {
    storage_management = var.storage_management
  }

  nsg_ids = [data.oci_core_network_security_groups.misc_labs_nsg.network_security_groups[0].id]

  lifecycle {
    ignore_changes = [display_name, hostname]
  }
}
