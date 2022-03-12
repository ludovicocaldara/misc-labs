resource "oci_database_data_guard_association" "data_guard_association" {
    depends_on = [oci_database_db_system.db_system]
	
    creation_type = "NewDbSystem"
    database_admin_password = oci_database_db_system.db_system.db_home[0].database[0].admin_password
    database_id = oci_database_db_system.db_system.db_home[0].database[0].id
    delete_standby_db_home_on_delete = true
    protection_mode = "MAXIMUM_PERFORMANCE"
    transport_type = "ASYNC"
    is_active_data_guard_enabled = true

    # peer_sid_prefix = var.data_guard_association_peer_sid_prefix
    # peer_db_unique_name = var.data_guard_association_peer_db_unique_name

    #--only for existing dbsystem
    # peer_vm_cluster_id = oci_database_vm_cluster.test_vm_cluster.id
    # peer_db_home_id = oci_database_db_system.db_system2.db_home[0].id
    # peer_db_system_id = oci_database_db_system.db_system2.id

    #--only for new dbsystem:
    availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
    display_name    = "${var.lab_name}2"
    hostname        = "${var.lab_name}2"
    nsg_ids         = [data.oci_core_network_security_groups.misc_labs_nsg.network_security_groups[0].id]
    shape           = var.db_system_shape
    subnet_id       = oci_core_subnet.db_subnet.id

    # database_software_image_id = oci_database_database_software_image.test_database_software_image.id
    # backup_network_nsg_ids = var.data_guard_association_backup_network_nsg_ids

}
