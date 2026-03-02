locals {
  landing_zone_state_path = coalesce(var.landing_zone_state_path, "../landing-zone/terraform.tfstate")
}

data "terraform_remote_state" "landing_zone" {
  count   = local.landing_zone_state_path == null ? 0 : 1
  backend = "local"

  config = {
    path = local.landing_zone_state_path
  }
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = var.ad_number
}

locals {
  landing_zone_outputs = local.landing_zone_state_path == null ? {
    vcn_id                 = null
    private_route_table_id = null
  } : data.terraform_remote_state.landing_zone[0].outputs
}

data "oci_core_vcn" "landing_zone" {
  vcn_id = local.landing_zone_outputs.vcn_id
}

data "oci_core_route_table" "landing_zone_private" {
  count         = local.landing_zone_outputs.private_route_table_id == null ? 0 : 1
  route_table_id = local.landing_zone_outputs.private_route_table_id
}

data "oci_core_network_security_groups" "misc_labs_nsg" {
  display_name   = "misc_labs_nsg"
  compartment_id = var.compartment_ocid
}
