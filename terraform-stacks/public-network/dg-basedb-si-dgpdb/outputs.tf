output "vcn_id" {
  value       = oci_core_vcn.lab_vcn.id
  description = "OCID of the standalone public VCN created by this stack."
}

output "subnet_id" {
  value       = oci_core_subnet.lab_subnet.id
  description = "OCID of the public DB subnet created by this stack."
}

output "network_security_group_id" {
  value       = oci_core_network_security_group.lab_nsg.id
  description = "OCID of the DB network security group created by this stack."
}

output "db_system_ids" {
  value       = [for db_system in oci_database_db_system.db_system : db_system.id]
  description = "OCIDs of the DB systems created by this stack."
}
