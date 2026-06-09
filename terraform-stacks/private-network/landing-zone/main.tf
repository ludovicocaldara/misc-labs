locals {
  tags_freeform = merge({ "stack" = "baseline" }, var.freeform_tags)
}

data "oci_core_services" "all_services" {}

resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = replace(substr(var.name_prefix, 0, 14), "/[^a-zA-Z0-9]/", "a")

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

resource "oci_core_nat_gateway" "nat" {
  count          = var.enable_nat_gateway ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-nat"

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

resource "oci_core_service_gateway" "sgw" {
  count          = var.enable_service_gateway ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-sgw"

  services {
    # Often you'll filter for "All .* Services In Oracle Services Network".
    service_id = data.oci_core_services.all_services.services[0].id
  }

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

resource "oci_core_route_table" "rt_private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-rt-private"

  dynamic "route_rules" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.nat[0].id
    }
  }

  dynamic "route_rules" {
    for_each = var.enable_service_gateway ? [1] : []
    content {
      destination       = data.oci_core_services.all_services.services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.sgw[0].id
    }
  }

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

# Private subnet that hosts the OCI Bastion endpoint
resource "oci_core_subnet" "bastion_endpoint_subnet" {
  compartment_id              = var.compartment_ocid
  vcn_id                      = oci_core_vcn.vcn.id
  cidr_block                  = var.bastion_subnet_cidr
  display_name                = "${var.name_prefix}-subnet-bastion-endpoint"
  prohibit_public_ip_on_vnic  = true
  route_table_id              = oci_core_route_table.rt_private.id

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

resource "oci_bastion_bastion" "bastion" {
  bastion_type                   = "STANDARD"
  compartment_id                 = var.compartment_ocid
  target_subnet_id               = oci_core_subnet.bastion_endpoint_subnet.id
  name                           = "${var.name_prefix}-bastion"
  client_cidr_block_allow_list   = split(",", var.client_cidr_block_allow_list)
  max_session_ttl_in_seconds   = var.max_session_ttl_in_seconds

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}
