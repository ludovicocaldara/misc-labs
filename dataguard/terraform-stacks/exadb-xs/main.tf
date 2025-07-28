resource "oci_database_exascale_db_storage_vault" "fake_exaxs_storage_vault" {
    #Required
    availability_domain = var.availablity_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availablity_domain_name
    compartment_id = var.compartment_ocid
    display_name = "ExaCS Storage Vault"
    high_capacity_database_storage {
        #Required
        total_size_in_gbs = 220
    }
}

data "oci_database_gi_version_minor_versions" "gi_minor_versions" {
  version = "23.0.0.0"

  availability_domain = var.availablity_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availablity_domain_name
  compartment_id                 = var.compartment_ocid
  shape_family = "EXADB_XS"
}

resource "oci_database_exadb_vm_cluster" "fake_exaxs_vm_cluster" {
    availability_domain = var.availablity_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availablity_domain_name
    backup_subnet_id = oci_core_subnet.Backup_Subnet.id
    compartment_id = var.compartment_ocid
    display_name = "ExaXS VM Cluster"
    exascale_db_storage_vault_id = oci_database_exascale_db_storage_vault.fake_exaxs_storage_vault.id
    grid_image_id = var.grid_image_id_id == "" ? lookup(data.oci_database_gi_version_minor_versions.gi_minor_versions.gi_minor_versions[0], "grid_image_id") : var.grid_image_id_id
#    grid_image_id = "ocid1.dbpatch.oc1.eu-frankfurt-1.antheljst5t4sqqaim77c3lo3jo2qdp23f2ba3vqjg76nnjrbcuj2ibzavoa"
    hostname = "ludoxs"
    shape = "ExaDbXS"

    node_config {
      enabled_ecpu_count_per_node          = 4
      total_ecpu_count_per_node            = 4
      vm_file_system_storage_size_gbs_per_node = 280
    }

    node_resource {
      node_name = "ludoxs1"
    }
    node_resource {
      node_name = "ludoxs2"
   }

   ssh_public_keys = [var.public_key]
   subnet_id = oci_core_subnet.Client_Subnet.id

   #Optional
   cluster_name = "ludoxsclu"
   license_model = "BRING_YOUR_OWN_LICENSE"
 }
