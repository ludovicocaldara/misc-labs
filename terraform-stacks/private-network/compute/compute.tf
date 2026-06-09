locals {
  instance_image_id = var.image_ocid != "" ? var.image_ocid : data.oci_core_images.oracle_linux_images.images[0].id
}

resource "oci_core_instance" "compute" {
  count               = var.num_compute
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  shape               = var.compute_shape
  display_name        = "${var.lab_name}${count.index}"

  shape_config {
    ocpus         = var.shape_ocpus
    memory_in_gbs = var.shape_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = local.instance_image_id
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.lab_subnet.id
    assign_public_ip          = false
    assign_private_dns_record = true
    display_name              = "${var.lab_name}${count.index}-vnic"
    hostname_label            = "${var.lab_name}${count.index}"
    nsg_ids                   = [oci_core_network_security_group.lab_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  defined_tags  = var.defined_tags
  freeform_tags = local.tags_freeform
}

output "compute_private_ips" {
  value = [for i in oci_core_instance.compute : i.private_ip]
}
