data "oci_core_vcns" "misc_labs_vcn" {
  display_name   = "misc_labs_vcn"
  compartment_id = var.compartment_ocid
}

data "oci_core_route_tables" "misc_labs_rt" {
  display_name   = "misc_labs_rt"
  compartment_id = var.compartment_ocid
}


data "oci_core_nat_gateways" "misc_labs_nat_gateway" {
  display_name   = "misc_labs_nat_gateway"
  compartment_id = var.compartment_ocid
}


data "oci_core_security_lists" "misc_labs_securitylist" {
  display_name   = "misc_labs_securitylist"
  compartment_id = var.compartment_ocid
}


resource "oci_core_route_table" "misc_labs_priv_rt" {
  display_name   = "priv_rt_${var.lab_name}_${var.resId}"

  compartment_id = var.compartment_ocid
  vcn_id            = data.oci_core_vcns.misc_labs_vcn.virtual_networks[0].id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_nat_gateways.misc_labs_nat_gateway.nat_gateways[0].id
  }
}


# ---------------------------------------------
# Setup the subnet
# ---------------------------------------------
resource "oci_core_subnet" "lab_subnet" {
  display_name      = "subnet_${var.lab_name}_${var.resId}"
  dns_label         = "${var.lab_name}-${var.resId}"

  compartment_id    = var.compartment_ocid
  vcn_id            = data.oci_core_vcns.misc_labs_vcn.virtual_networks[0].id
  cidr_block        = "10.0.${var.resId}.0/24"
  route_table_id    = oci_core_route_table.misc_labs_priv_rt.id
  security_list_ids = [data.oci_core_security_lists.misc_labs_securitylist.security_lists[0].id]
}
