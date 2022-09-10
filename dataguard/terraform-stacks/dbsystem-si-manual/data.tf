data "oci_core_instances" "olam" {
  compartment_id = var.compartment_ocid
  display_name = "olam"
}

data "oci_core_vnic_attachments" "olam_vnic_attachments" {
  compartment_id = var.compartment_ocid
  instance_id = data.oci_core_instances.olam.instances[0].id
}

data "oci_core_vnic" "olam_vnic" {
  vnic_id = data.oci_core_vnic_attachments.olam_vnic_attachments.vnic_attachments[0].vnic_id
}

data "template_file" "repo_setup" {
  template = file("${path.root}/scripts/01_repo_setup.sh")
}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.compartment_ocid
}

data "oci_core_network_security_groups" "misc_labs_nsg" {
  display_name   = "misc_labs_nsg"
  compartment_id = var.compartment_ocid
}
