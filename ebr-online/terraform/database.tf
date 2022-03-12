
resource "random_password" "adb_password" {
  length           = 20
  special          = true
  number           = true
  upper            = true
  lower            = true
  override_special = "_%@+!"
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
}

resource "oci_database_autonomous_database" "demo_adb" {
    compartment_id           = var.compartment_ocid
    db_name                  = "demoadb"
    is_free_tier             = false
    cpu_core_count           = 1
    data_storage_size_in_tbs = 1
    admin_password           = random_password.adb_password.result
}
