output "vcn_id" { value = oci_core_vcn.vcn.id }

output "private_route_table_id" {
  value       = oci_core_route_table.rt_private.id
  description = "Route table to associate to lab subnets (optional; lab stack can create its own too)."
}

output "bastion_id" { value = oci_bastion_bastion.bastion.id }

output "bastion_endpoint_subnet_id" { value = oci_core_subnet.bastion_endpoint_subnet.id }
output "bastion_endpoint_subnet_cidr" { value = var.bastion_subnet_cidr }