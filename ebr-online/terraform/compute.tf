resource "tls_private_key" "provisioner_keypair" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}

resource "oci_core_instance" "demo_vm" {
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  shape               = var.vm_shape
  display_name        = var.compute_name

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_id               = data.oci_core_images.vm_images.images[0].id
    source_type             = "image"
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    assign_public_ip        = true
    subnet_id               = oci_core_subnet.demo-public-subnet.id
    display_name            = "${var.compute_name}-vnic"
    hostname_label          = var.compute_name
  }

  metadata = {
    ssh_authorized_keys = "${tls_private_key.provisioner_keypair.public_key_openssh}"
  }

}


resource "null_resource" "oic_setup" {
  depends_on = [oci_core_instance.demo_vm, null_resource.demo_vm_adb_wallet]

  provisioner "file" {
    source      = "conf/setup.sh"
    destination = "/tmp/setup.sh"
    connection  {
      type        = "ssh"
      host        = oci_core_instance.demo_vm.public_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.provisioner_keypair.private_key_pem

    }
  }


  provisioner "remote-exec" {
    connection  {
      type        = "ssh"
      host        = oci_core_instance.demo_vm.public_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.provisioner_keypair.private_key_pem
    }
    inline = [<<EOF
      chmod +x /tmp/setup.sh
      sudo /tmp/setup.sh
    EOF
    ]
  }
}

resource "null_resource" "demo_vm_adb_wallet" {
  depends_on = [oci_core_instance.demo_vm, oci_database_autonomous_database_wallet.demo_adb_wallet]

  provisioner "file" {
    content = oci_database_autonomous_database_wallet.demo_adb_wallet.content
    destination = "/tmp/adb_wallet.zip.base64"
    connection  {
      type        = "ssh"
      host        = oci_core_instance.demo_vm.public_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.provisioner_keypair.private_key_pem

    }
  }

}
