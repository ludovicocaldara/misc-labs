# -----------------------------------------------
# Setup the VCN.
# -----------------------------------------------
resource "oci_core_vcn" "misc_labs_vcn" {
  display_name   = "misc_labs_vcn"

  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  dns_label      = "misclabs"
}

# -----------------------------------------------
# Setup the Internet Gateway
# -----------------------------------------------
resource "oci_core_internet_gateway" "misc_labs_igw" {
  display_name   = "misc_labs_igw"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.misc_labs_vcn.id
  enabled        = "true"
}

# -----------------------------------------------
# Setup the Route Table
# -----------------------------------------------
resource "oci_core_route_table" "misc_labs_rt" {
  display_name   = "misc_labs_rt"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.misc_labs_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.misc_labs_igw.id
  }
}

resource "oci_core_nat_gateway" "misc_labs_nat_gateway" {
    display_name   = "misc_labs_nat_gateway"
    compartment_id = var.compartment_ocid	
    vcn_id         = oci_core_vcn.misc_labs_vcn.id
}

# -----------------------------------------------
# Setup the Security List
# -----------------------------------------------
resource "oci_core_security_list" "misc_labs_securitylist" {
  display_name   = "misc_labs_securitylist"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.misc_labs_vcn.id

  # -------------------------------------------
  # Egress: Allow everything
  # -------------------------------------------
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }


  # -------------------------------------------
  # Ingress protocol 6: TCP
  # -------------------------------------------
  # Allow SSH from everywhere
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow SQL*Net communication within the VCN only
  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = 1521
      max = 1531
    }
  }

  # ------------------------------------------
  # protocol 1: ICMP: allow explicitly from VCN and everywhere
  # ------------------------------------------
  ingress_security_rules {
    protocol = 1
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = 1
    source   = var.vcn_cidr
  }
}


# ---------------------------------------------
# Setup the Security Group
# ---------------------------------------------
resource "oci_core_network_security_group" "misc_labs_nsg" {
  display_name   = "misc_labs_nsg"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.misc_labs_vcn.id
}

# ---------------------------------------------
# Setup the subnet
# ---------------------------------------------
resource "oci_core_subnet" "admin_subnet" {
  display_name      = "admin_subnet"
  dns_label         = "admin"

  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.misc_labs_vcn.id
  cidr_block        = var.admin_subnet_cidr
  route_table_id    = oci_core_route_table.misc_labs_rt.id
  security_list_ids = [oci_core_security_list.misc_labs_securitylist.id]
}

