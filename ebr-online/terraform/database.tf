resource "random_password" "adb_wallet_password" {
  length           = 10
  special          = false
  numeric           = true
  upper            = true
  lower            = true
  override_special = "_%@+!"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}

resource "random_password" "adb_password" {
  length           = 20
  special          = true
  numeric           = true
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
    is_free_tier             = true
    cpu_core_count           = 1
    data_storage_size_in_tbs = 1
    admin_password           = random_password.adb_password.result
}

resource "oci_database_autonomous_database_wallet" "demo_adb_wallet" {
    depends_on = [oci_database_autonomous_database.demo_adb]
    autonomous_database_id = oci_database_autonomous_database.demo_adb.id
    password               = random_password.adb_wallet_password.result
    base64_encode_content  = "true"
    generate_type          = "ALL"
}
