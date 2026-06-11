
resource "oci_core_vcn" "lab_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.lab_name}-vcn"
  dns_label      = var.vcn_dns_label

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

resource "oci_core_internet_gateway" "lab_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "${var.lab_name}-igw"
  enabled        = true

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

resource "oci_core_route_table" "lab_public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "${var.lab_name}-rt-public"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.lab_igw.id
  }

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

resource "oci_core_subnet" "lab_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.lab_vcn.id
  cidr_block                 = var.subnet_cidr
  display_name               = "${var.lab_name}-subnet"
  dns_label                  = var.subnet_dns_label
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.lab_public.id

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}


resource "oci_core_network_security_group" "lab_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "${var.lab_name}-nsg"
  defined_tags   = var.defined_tags
  freeform_tags  = local.tags_freeform
}

variable "public_allowed_tcp_ports" {
  type = map(object({ min = number, max = number }))
  default = {
    ssh = { min = 22, max = 22 }
    db  = { min = 1521, max = 1521 }
  }
}


locals {
  public_ingress_rules = {
    for rule in flatten([
      for cidr in var.public_ingress_cidrs : [
        for name, port_range in var.public_allowed_tcp_ports : {
          key        = "${replace(replace(cidr, ".", "-"), "/", "-")}-${name}"
          cidr       = cidr
          name       = name
          port_range = port_range
        }
      ]
    ]) : rule.key => rule
  }
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.lab_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow outbound traffic from DB systems"
}

resource "oci_core_network_security_group_security_rule" "ingress_public" {
  for_each = local.public_ingress_rules

  network_security_group_id = oci_core_network_security_group.lab_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = each.value.cidr
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = each.value.port_range.min
      max = each.value.port_range.max
    }
  }

  description = "Allow ${each.value.name} from ${each.value.cidr} to lab targets on port ${each.value.port_range.min}-${each.value.port_range.max}"
}
