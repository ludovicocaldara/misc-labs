module "dbhost" {
  count = 2
  source                = "./modules/dbhost"
  availability_domain   = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id        = var.compartment_ocid
  subnet_id             = oci_core_subnet.db_subnet.id
  ssh_public_key        = var.ssh_public_key
  ssh_private_key       = local.ssh_private_key
  subnet_cidr           = var.db_subnet_cidr
  vcn_cidr		= data.oci_core_vcns.misc_labs_vcn.virtual_networks[0].cidr_block
  dbhost_name		= format("%s%s", var.dbhost_name, count.index+1)

}
