resource "oci_database_db_system" "db_system" {
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  database_edition    = var.db_edition

  db_home {
    database {
      admin_password = var.db_admin_password
      db_name        = "c${var.lab_name}"
      character_set  = var.character_set
      ncharacter_set = var.n_character_set
      db_workload    = var.db_workload
      pdb_name        = "p${var.lab_name}"

      db_backup_config {
        auto_backup_enabled = false
      }
    }

    db_version   = var.db_version
    display_name = "dbhome-${var.lab_name}"
  }

  db_system_options {
    storage_management = "LVM"
  }

  disk_redundancy         = var.db_disk_redundancy
  shape                   = var.db_system_shape
  subnet_id               = oci_core_subnet.db_subnet.id
  ssh_public_keys         = [var.ssh_public_key]
  display_name            = "${var.lab_name}1"
  hostname                = "${var.lab_name}1"
  data_storage_size_in_gb = var.data_storage_size_in_gb
  license_model           = var.license_model
  node_count              = var.node_count
  nsg_ids                 = [data.oci_core_network_security_groups.misc_labs_nsg.network_security_groups[0].id]
  lifecycle {
    ignore_changes = [
      display_name, hostname,
    ]
  }
}


resource "null_resource" "db_system_provisioner" {
  depends_on = [oci_database_db_system.db_system]

  provisioner "file" {
    content     = data.template_file.repo_setup.rendered
    destination = "${local.repo_script}.${oci_database_db_system.db_system.hostname}"
    connection  {
      type        = "ssh"
      host        = data.oci_core_vnic.olam_vnic.public_ip_address
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = local.ssh_private_key

    }
  }

  provisioner "remote-exec" {
    connection  {
      type        = "ssh"
      host        = data.oci_core_vnic.olam_vnic.public_ip_address
      agent       = false
      timeout     = "30m"
      user        = var.vm_user
      private_key = local.ssh_private_key
    }
   
    inline = [
      "scp  -o StrictHostKeyChecking=no ${local.repo_script}.${oci_database_db_system.db_system.hostname} ${oci_database_db_system.db_system.hostname}.${oci_database_db_system.db_system.domain}:${local.repo_script}",
      "ssh  -o StrictHostKeyChecking=no opc@${oci_database_db_system.db_system.hostname}.${oci_database_db_system.db_system.domain} chmod +x ${local.repo_script}",
      "ssh  -o StrictHostKeyChecking=no opc@${oci_database_db_system.db_system.hostname}.${oci_database_db_system.db_system.domain} sudo ${local.repo_script}",
    ]

   }
}

