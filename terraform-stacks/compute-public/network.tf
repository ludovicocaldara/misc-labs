resource "oci_core_network_security_group" "lab_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcns.landing_zone_vcn.virtual_networks[0].id
  display_name   = "${var.lab_name}-nsg"
  defined_tags   = var.defined_tags
  freeform_tags  = var.freeform_tags
}

resource "oci_core_network_security_group_security_rule" "ingress_from_bastion" {
  for_each = {
    for p in distinct([
      for token in split(",", var.bastion_allowed_tcp_ports_csv) : trimspace(token)
      if trimspace(token) != ""
    ]) : p => tonumber(p)
  }

  network_security_group_id = oci_core_network_security_group.lab_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = data.oci_core_subnets.bastion_endpoint_subnet.subnets[0].cidr_block
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }

  description = "Allow traffic from bastion endpoint subnet to lab targets on port ${each.value}"
}