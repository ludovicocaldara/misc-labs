module "olam" {
  source                = "./modules/olam"
  availability_domain   = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id        = var.compartment_ocid
  subnet_id             = oci_core_subnet.admin_subnet.id
  ssh_public_key        = var.ssh_public_key
  ssh_private_key       = local.ssh_private_key
  subnet_cidr           = var.admin_subnet_cidr
  vcn_cidr              = var.vcn_cidr
}

