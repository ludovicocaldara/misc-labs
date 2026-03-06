data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = var.ad_number
}

data "oci_core_images" "oracle_linux_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = var.compute_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_bastion_bastions" "bastions" {
  compartment_id = var.compartment_ocid

  filter {
    name   = "name"
    values = ["${var.landing_zone_name}-bastion"]
  }
}

locals {
  bastion_id = length(data.oci_bastion_bastions.bastions.bastions) > 0 ? data.oci_bastion_bastions.bastions.bastions[0].id : null
}

data "oci_bastion_bastion" "bastion" {
  count = local.bastion_id != null ? 1 : 0

  bastion_id = local.bastion_id
}

data "oci_core_vcns" "landing_zone_vcn" {
  compartment_id = var.compartment_ocid

  filter {
    name   = "display_name"
    values = ["${var.landing_zone_name}-vcn"]
  }
}

data "oci_core_subnets" "bastion_endpoint_subnet" {
  compartment_id = var.compartment_ocid

  filter {
    name   = "display_name"
    values = ["${var.landing_zone_name}-subnet-bastion-endpoint"]
  }
}

output "bastion_endpoint_cidr" {
  value = data.oci_core_subnets.bastion_endpoint_subnet.subnets[0].cidr_block
}

data "oci_core_nat_gateways" "landing_zone_nat_gateway" {
  compartment_id = var.compartment_ocid

  filter {
    name   = "display_name"
    values = ["${var.landing_zone_name}-nat"]
  }
}

data "oci_core_route_tables" "landing_zone_private_route_table" {
  compartment_id = var.compartment_ocid

  filter {
    name   = "display_name"
    values = ["${var.landing_zone_name}-rt-private"]
  }
}