resource "oci_database_db_system" "standby_db_system" {
  availability_domain     = data.oci_identity_availability_domain.ad.name
  compartment_id          = var.compartment_ocid
  subnet_id               = oci_core_subnet.lab_subnet.id
  shape                   = var.db_shape
  ssh_public_keys         = [var.ssh_public_key]
  hostname                = "${var.lab_name}2"
  display_name            = "${var.lab_name}2"
  license_model           = var.license_model
  node_count              = var.node_count
  cpu_core_count          = var.cpu_core_count
  data_storage_percentage = var.data_storage_percentage
  data_storage_size_in_gb = var.data_storage_size_in_gb
  database_edition        = var.db_edition
  source_db_system_id    = oci_database_db_system.db_system.id
  primary_db_system_id    = oci_database_db_system.db_system.id
  source                  = "DATAGUARD"

  db_home {
    display_name = "${var.lab_name}2-Home"
    db_version   = var.db_version

    database {
      admin_password               = var.db_admin_password
      db_unique_name = "${var.lab_name}_site2"
      protection_mode    = "MAXIMUM_PERFORMANCE"
      transport_type     = "ASYNC"
      is_active_data_guard_enabled = true
    }
  }

  db_system_options {
    storage_management = var.storage_management
  }

  nsg_ids = [oci_core_network_security_group.lab_nsg.id]

  lifecycle {
    ignore_changes = [display_name, hostname]
  }
}
