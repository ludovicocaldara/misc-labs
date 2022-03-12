# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------
# olam-host.tf
#

data "template_file" "repo_setup" {
  template = file("${path.module}/scripts/01_repo_setup.sh")
}

data "template_file" "u01_setup" {
  template = file("${path.module}/scripts/02_u01_setup.sh")

  vars = {
	attachment_type = data.oci_core_volume_attachments.olam_disk_device.volume_attachments[0].attachment_type
	ipv4            = data.oci_core_volume_attachments.olam_disk_device.volume_attachments[0].ipv4
	iqn             = data.oci_core_volume_attachments.olam_disk_device.volume_attachments[0].iqn
	port            = data.oci_core_volume_attachments.olam_disk_device.volume_attachments[0].port
	vcn_cidr        = var.vcn_cidr
  }
}

# ---------------------------------------------------------
# here's where the scripts will be copied on the VM
# ---------------------------------------------------------
locals {
  repo_script     = "/tmp/01_repo_setup.sh"
  u01_script      = "/tmp/02_u01_setup.sh"
  varlib_script      = "/tmp/03_varlib_setup.sh"
}



# ---------------------------------------------------------
# Data: attached volumes
# it requires the creation of the attachment resources first.
# it's used to get the variables for the setup script that partitions the volume for the creation of /u01 and the asmdisk
# ---------------------------------------------------------
data "oci_core_volume_attachments" "olam_disk_device" {
    depends_on = [oci_core_instance.olam_vm, oci_core_volume_attachment.olam_volume_attachment, oci_core_volume.olam_disk]

    compartment_id  = var.compartment_id
    instance_id     = oci_core_instance.olam_vm.id
#    volume_id       = oci_core_volume.olam_disk.id
}


# ---------------------------------------------------------
# Resource: Instance creation
# It uses the last build of 7.9, Flex shape, CPU and RAM defined in the variables.
# ---------------------------------------------------------
resource "oci_core_instance" "olam_vm" {
    availability_domain = var.availability_domain
    compartment_id      = var.compartment_id
    shape               = var.vm_shape
    display_name        = var.olam_name

    source_details {
        source_id = data.oci_core_images.vm_images.images[0].id

        source_type = "image"
        boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    }

    #shape_config {
    #    ocpus = var.instance_ocpus
    #    memory_in_gbs = var.instance_memgb
    #}

    create_vnic_details {
        assign_public_ip = true
        subnet_id               = var.subnet_id
        display_name            = "${var.olam_name}-vnic"
        hostname_label          = var.olam_name
    }

    # ---------------------------------------------------------
    # The bootstrap.sh script is copied and executed as bootstrap script on the VM.
    # Iit starts the OCI services.  This is fundamental to discover iscsi disks in this case 
    # but it can do other nice things such as configuring secondary VNICs if added
    # ---------------------------------------------------------
    metadata = {
        # according to the doc: public key entries separated by newline
        ssh_authorized_keys = "${var.ssh_public_key}"
	user_data = base64encode(file("${path.module}/scripts/bootstrap.sh"))
    } 
}

# ---------------------------------------------------------
# Resource: block volume creation for /u01 (olam_disk[0]) and ASM (olam_disk[1])
# ---------------------------------------------------------
resource "oci_core_volume" "olam_disk" {
    # volume 0 for u01, volume 1 for /var/lib/containers
    count=1
    availability_domain = var.availability_domain
    compartment_id      = var.compartment_id
    display_name = format("%s-disk%02d",var.olam_name, count.index+1)
    size_in_gbs = var.olam_disk_size
}

# ---------------------------------------------------------
# Resource: attachment of the volume to the instance
# The bootstrap.sh will take care of the iscsi discovery.
# ---------------------------------------------------------
resource "oci_core_volume_attachment" "olam_volume_attachment" {
    count=1
    attachment_type = "iscsi"
    instance_id = oci_core_instance.olam_vm.id
    volume_id = oci_core_volume.olam_disk[count.index].id
    is_read_only = false
    is_shareable = true
}



# ---------------------------------------------------------
# Resource: null_resource, executes 2 provisioners:
# provisioner "file" parse the template script and copy it on the VM
# provisioner "remote-exec" execute some commands on the VM, including the scripts.
# In this block it executes the first two scripts.
#
# Because the resource is atomic, it might be a good idea to split them in two different resources
# so that if the second fails, the first does not execute again
# ---------------------------------------------------------
resource "null_resource" "olam_setup" {
  depends_on = [oci_core_instance.olam_vm, oci_core_volume_attachment.olam_volume_attachment, oci_core_volume.olam_disk]

  provisioner "file" {
    content     = data.template_file.repo_setup.rendered
    destination = local.repo_script
    connection  {
      type        = "ssh"
      host        = oci_core_instance.olam_vm.public_ip
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = var.ssh_private_key

    }
  }
  provisioner "file" {
    content     = data.template_file.u01_setup.rendered
    destination = local.u01_script
    connection  {
      type        = "ssh"
      host        = oci_core_instance.olam_vm.public_ip
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = var.ssh_private_key

    }
  }

  provisioner "remote-exec" {
    connection  {
      type        = "ssh"
      host        = oci_core_instance.olam_vm.public_ip
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = var.ssh_private_key
    }

    inline = [
       "chmod +x ${local.repo_script}",
       "sudo ${local.repo_script}",
       "chmod +x ${local.u01_script}",
       "sudo ${local.u01_script}",
    ]

   }

}

