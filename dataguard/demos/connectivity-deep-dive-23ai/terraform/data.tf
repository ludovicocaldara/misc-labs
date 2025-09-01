data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = var.ad_number
}

data "oci_core_network_security_groups" "misc_labs_nsg" {
  display_name   = "misc_labs_nsg"
  compartment_id = var.compartment_ocid
}
