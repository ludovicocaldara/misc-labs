# -----------------------------------------------
# Setup the VCN.
# -----------------------------------------------
resource "oci_core_vcn" "demovcn" {
  display_name   = "demo-vcn"

  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  dns_label      = "demovcn"
}

# -----------------------------------------------
# Setup the Internet Gateway
# -----------------------------------------------
resource "oci_core_internet_gateway" "demo-internet-gateway" {
  display_name   = "demo-igw"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
  enabled        = "true"
}

# -----------------------------------------------
# Setup the Route Table
# -----------------------------------------------
resource "oci_core_route_table" "demo-public-rt" {
  display_name   = "demo-routetable"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.demo-internet-gateway.id
  }
}


# -----------------------------------------------
# Setup the Security List
# -----------------------------------------------
resource "oci_core_security_list" "demo-security-list" {
  display_name   = "demo-seclist"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id

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
  # protocol 1: ICMP: allow explicitly from subnet and everywhere
  # ------------------------------------------
  ingress_security_rules {
    protocol = 1
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = 1
    source   = var.subnet_cidr
  }
}


# ---------------------------------------------
# Setup the Security Group
# ---------------------------------------------
resource "oci_core_network_security_group" "demo-network-security-group" {
  display_name   = "demo-nsg"

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
}

# ---------------------------------------------
# Setup the subnet
# ---------------------------------------------
resource "oci_core_subnet" "demo-public-subnet" {
  display_name      = "demo-pubsubnet"
  dns_label         = "pub"

  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.demovcn.id
  cidr_block        = var.subnet_cidr
  route_table_id    = oci_core_route_table.demo-public-rt.id
  security_list_ids = [oci_core_security_list.demo-security-list.id]
}

