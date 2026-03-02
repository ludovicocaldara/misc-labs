locals {
  landing_zone_has_private_rt = try(data.terraform_remote_state.landing_zone.outputs.private_route_table_id, null) != null
}

resource "oci_core_route_table" "db_private" {
  count = local.landing_zone_has_private_rt ? 0 : 1

  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcn.landing_zone.id
  display_name   = "${var.lab_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_vcn.landing_zone.default_nat_gateway_id
  }
}

resource "oci_core_subnet" "lab_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = data.oci_core_vcn.landing_zone.id
  cidr_block                 = var.db_subnet_cidr
  display_name               = "${var.lab_name}-db-subnet"
  dns_label                  = var.db_subnet_dns_label
  prohibit_public_ip_on_vnic = true
  route_table_id = local.landing_zone_has_private_rt ?
    data.terraform_remote_state.landing_zone.outputs.private_route_table_id :
    oci_core_route_table.db_private[0].id

  nsg_ids = [data.oci_core_network_security_groups.misc_labs_nsg.network_security_groups[0].id]
}