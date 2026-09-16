terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "8.20.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.0"
    }
  }
}

provider "oci" {
  region = var.region
}

# -----------------
# Variables
# -----------------

variable "region" {
  description = "OCI region (for example, us-phoenix-1)."
  type        = string
  default     = "us-phoenix-1"
}

variable "compartment_ocid" {
  description = "Target compartment OCID."
  type        = string
}

variable "availability_domain" {
  description = "Availability Domain for ExaDB-XS resources (for example, PHX-AD-1)."
  type        = string
}

variable "vcn_cidr" {
  description = "VCN CIDR."
  type        = string
  default     = "10.40.0.0/16"
}

variable "backup_subnet_cidr" {
  description = "Private backup subnet CIDR."
  type        = string
  default     = "10.40.2.0/24"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR used by both VM clusters."
  type        = string
  default     = "10.40.10.0/24"
}

variable "vault_highcap_size_gb" {
  description = "Total High Capacity storage (GiB) in the shared Exascale Storage Vault."
  type        = number
  default     = 500
}

variable "ssh_public_key" {
  description = "Optional OpenSSH public key to inject into the cluster nodes."
  type        = string
  default     = null
}

variable "grid_image_id" {
  description = <<-EOT
    Optional Grid Infrastructure image OCID override for ExaDB-XS.

    Leave this unset or empty to discover a compatible provisioning-capable
    image from gi_version, region, availability_domain, compartment_ocid, and
    shape_family = EXADB_XS. Set it only to pin a known-good GI image.
  EOT
  type        = string
  default     = null
}

variable "gi_version" {
  description = "Grid Infrastructure major version used for dynamic ExaDB-XS image lookup."
  type        = string
  default     = "23.0.0.0"
}

variable "enabled_ecpu_per_node" {
  description = "Enabled ECPUs per ExaDB-XS cluster node."
  type        = number
  default     = 8
}

variable "total_ecpu_per_node" {
  description = "Total ECPU cap per ExaDB-XS cluster node."
  type        = number
  default     = 8
}

variable "vmfs_size_gb_per_node" {
  description = "VM file-system storage (GiB) per cluster node."
  type        = number
  default     = 250
}

variable "db_version" {
  description = "Database version."
  type        = string
  default     = "23.26.2.0.0"
}

variable "dgpdb1_name" {
  description = "CDB name for the independent DGPDB peer on Cluster A."
  type        = string
  default     = "dgpdb1"
}

variable "dgpdb2_name" {
  description = "CDB name for the independent DGPDB peer on Cluster B."
  type        = string
  default     = "dgpdb2"
}

variable "pdb_name" {
  description = "Initial PDB name created in both CDBs."
  type        = string
  default     = "mypdb"
}

variable "db_admin_password" {
  description = "SYS/ADMIN password for both CDBs."
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.db_admin_password) >= 12 &&
      can(regex("[A-Z]", var.db_admin_password)) &&
      can(regex("[a-z]", var.db_admin_password)) &&
      can(regex("[0-9]", var.db_admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.db_admin_password))
    )
    error_message = "db_admin_password must be >= 12 chars and include upper, lower, digit, and special character."
  }
}

variable "post_cluster_wait_seconds" {
  description = "Wait after clusters provision before creating DB Homes."
  type        = number
  default     = 900
}

variable "between_dbhomes_wait_seconds" {
  description = "Gap between serialized DB Home creates."
  type        = number
  default     = 300
}

variable "pre_database_wait_seconds" {
  description = "Gap after DB Homes before creating databases."
  type        = number
  default     = 120
}

# -----------------
# Networking
# -----------------

resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "exadb-xs-dgpdb-vcn"
  dns_label      = "exadbdgpdb"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-dgpdb-igw"
}

resource "oci_core_nat_gateway" "ngw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-dgpdb-ngw"
  block_traffic  = false
}

data "oci_core_services" "osn" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  osn_service      = one([for service in data.oci_core_services.osn.services : service])
  osn_service_id   = local.osn_service.id
  osn_service_cidr = local.osn_service.cidr_block
}

locals {
  provided_grid_image_id       = var.grid_image_id == null ? "" : trimspace(var.grid_image_id)
  use_discovered_grid_image_id = local.provided_grid_image_id == ""
}

data "oci_database_gi_version_minor_versions" "exadb_xs" {
  count = local.use_discovered_grid_image_id ? 1 : 0

  compartment_id                 = var.compartment_ocid
  availability_domain            = var.availability_domain
  is_gi_version_for_provisioning = true
  shape_family                   = "EXADB_XS"
  version                        = var.gi_version
}

locals {
  discovered_grid_image_ids = local.use_discovered_grid_image_id ? [
    for minor_version in coalesce(try(data.oci_database_gi_version_minor_versions.exadb_xs[0].gi_minor_versions, []), []) :
    minor_version.grid_image_id
    if try(trimspace(minor_version.grid_image_id), "") != ""
  ] : []

  discovered_grid_image_id = length(local.discovered_grid_image_ids) > 0 ? local.discovered_grid_image_ids[0] : null
  effective_grid_image_id  = local.provided_grid_image_id != "" ? local.provided_grid_image_id : local.discovered_grid_image_id
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-dgpdb-sgw"

  services {
    service_id = local.osn_service_id
  }
}

resource "oci_core_route_table" "rt_public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-dgpdb-rt-public"

  route_rules {
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "rt_private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-dgpdb-rt-private"

  route_rules {
    description       = "Default egress via NAT"
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }

  route_rules {
    description       = "Oracle Services Network via SGW"
    destination_type  = "SERVICE_CIDR_BLOCK"
    destination       = local.osn_service_cidr
    network_entity_id = oci_core_service_gateway.sgw.id
  }
}

resource "oci_core_security_list" "sl_common" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-dgpdb-sl-common"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 1521
      max = 1521
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 5500
      max = 5500
    }
  }
}

resource "oci_core_subnet" "subnet_public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "exadb-xs-dgpdb-public-subnet"
  route_table_id             = oci_core_route_table.rt_public.id
  security_list_ids          = [oci_core_security_list.sl_common.id]
  prohibit_public_ip_on_vnic = false
  dns_label                  = "public"
}

resource "oci_core_subnet" "subnet_backup" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  cidr_block                 = var.backup_subnet_cidr
  display_name               = "exadb-xs-dgpdb-backup-subnet"
  route_table_id             = oci_core_route_table.rt_private.id
  security_list_ids          = [oci_core_security_list.sl_common.id]
  prohibit_public_ip_on_vnic = true
  dns_label                  = "backup"
}

# -----------------
# ExaDB-XS RAC infrastructure
# -----------------

resource "oci_database_exascale_db_storage_vault" "vault" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "exadb-xs-dgpdb-vault"

  high_capacity_database_storage {
    total_size_in_gbs = var.vault_highcap_size_gb
  }
}

resource "oci_database_exadb_vm_cluster" "cluster_a" {
  compartment_id               = var.compartment_ocid
  availability_domain          = var.availability_domain
  subnet_id                    = oci_core_subnet.subnet_public.id
  backup_subnet_id             = oci_core_subnet.subnet_backup.id
  exascale_db_storage_vault_id = oci_database_exascale_db_storage_vault.vault.id

  display_name    = "exadb-xs-dgpdb-cluster-a"
  cluster_name    = "exadbdgpda"
  hostname        = "exadbdgpda"
  shape           = "ExaDbXS"
  ssh_public_keys = var.ssh_public_key == null ? [] : [var.ssh_public_key]
  grid_image_id   = local.effective_grid_image_id
  license_model   = "BRING_YOUR_OWN_LICENSE"

  node_config {
    enabled_ecpu_count_per_node              = var.enabled_ecpu_per_node
    total_ecpu_count_per_node                = var.total_ecpu_per_node
    vm_file_system_storage_size_gbs_per_node = var.vmfs_size_gb_per_node
  }

  node_resource { node_name = "node1" }
  node_resource { node_name = "node2" }

  timeouts {
    create = "6h"
    update = "6h"
    delete = "6h"
  }

  lifecycle {
    precondition {
      condition     = try(trimspace(local.effective_grid_image_id), "") != ""
      error_message = "Unable to determine a Grid Infrastructure image OCID. Set grid_image_id explicitly, or verify gi_version, availability_domain, region, compartment_ocid, and OCI support for EXADB_XS GI image discovery."
    }
  }
}

resource "oci_database_exadb_vm_cluster" "cluster_b" {
  compartment_id               = var.compartment_ocid
  availability_domain          = var.availability_domain
  subnet_id                    = oci_core_subnet.subnet_public.id
  backup_subnet_id             = oci_core_subnet.subnet_backup.id
  exascale_db_storage_vault_id = oci_database_exascale_db_storage_vault.vault.id

  display_name    = "exadb-xs-dgpdb-cluster-b"
  cluster_name    = "exadbdgpdb"
  hostname        = "exadbdgpdb"
  shape           = "ExaDbXS"
  ssh_public_keys = var.ssh_public_key == null ? [] : [var.ssh_public_key]
  grid_image_id   = local.effective_grid_image_id
  license_model   = "BRING_YOUR_OWN_LICENSE"

  node_config {
    enabled_ecpu_count_per_node              = var.enabled_ecpu_per_node
    total_ecpu_count_per_node                = var.total_ecpu_per_node
    vm_file_system_storage_size_gbs_per_node = var.vmfs_size_gb_per_node
  }

  node_resource { node_name = "node1" }
  node_resource { node_name = "node2" }

  timeouts {
    create = "6h"
    update = "6h"
    delete = "6h"
  }

  lifecycle {
    precondition {
      condition     = try(trimspace(local.effective_grid_image_id), "") != ""
      error_message = "Unable to determine a Grid Infrastructure image OCID. Set grid_image_id explicitly, or verify gi_version, availability_domain, region, compartment_ocid, and OCI support for EXADB_XS GI image discovery."
    }
  }
}

# -----------------
# One independent RAC CDB per cluster
# -----------------

resource "time_sleep" "post_clusters" {
  create_duration = "${var.post_cluster_wait_seconds}s"

  depends_on = [
    oci_database_exadb_vm_cluster.cluster_a,
    oci_database_exadb_vm_cluster.cluster_b,
  ]
}

resource "oci_database_db_home" "dgpdb1" {
  display_name  = "exadbxs-dgpdb1-home"
  db_version    = var.db_version
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = oci_database_exadb_vm_cluster.cluster_a.id

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [time_sleep.post_clusters]
}

resource "time_sleep" "after_dgpdb1_home" {
  create_duration = "${var.between_dbhomes_wait_seconds}s"
  depends_on      = [oci_database_db_home.dgpdb1]
}

resource "oci_database_db_home" "dgpdb2" {
  display_name  = "exadbxs-dgpdb2-home"
  db_version    = var.db_version
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = oci_database_exadb_vm_cluster.cluster_b.id

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [time_sleep.after_dgpdb1_home]
}

resource "time_sleep" "pre_databases" {
  create_duration = "${var.pre_database_wait_seconds}s"
  depends_on = [
    oci_database_db_home.dgpdb1,
    oci_database_db_home.dgpdb2,
  ]
}

resource "oci_database_database" "dgpdb1" {
  db_home_id = oci_database_db_home.dgpdb1.id
  source     = "NONE"

  database {
    db_name        = var.dgpdb1_name
    pdb_name       = var.pdb_name
    admin_password = var.db_admin_password
    character_set  = "AL32UTF8"
    ncharacter_set = "AL16UTF16"
    db_workload    = "OLTP"

    db_backup_config {
      auto_backup_enabled = false
    }
  }

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [time_sleep.pre_databases]
}

resource "oci_database_database" "dgpdb2" {
  db_home_id = oci_database_db_home.dgpdb2.id
  source     = "NONE"

  database {
    db_name        = var.dgpdb2_name
    pdb_name       = var.pdb_name
    admin_password = var.db_admin_password
    character_set  = "AL32UTF8"
    ncharacter_set = "AL16UTF16"
    db_workload    = "OLTP"

    db_backup_config {
      auto_backup_enabled = false
    }
  }

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [time_sleep.pre_databases]
}

# -----------------
# Outputs
# -----------------

output "vcn_id" {
  value = oci_core_virtual_network.vcn.id
}

output "subnet_public_id" {
  value = oci_core_subnet.subnet_public.id
}

output "subnet_backup_id" {
  value = oci_core_subnet.subnet_backup.id
}

output "storage_vault_id" {
  value = oci_database_exascale_db_storage_vault.vault.id
}

output "cluster_a_id" {
  value = oci_database_exadb_vm_cluster.cluster_a.id
}

output "cluster_b_id" {
  value = oci_database_exadb_vm_cluster.cluster_b.id
}

output "grid_image_id" {
  value = local.effective_grid_image_id
}

output "dgpdb1_dbhome_id" {
  value = oci_database_db_home.dgpdb1.id
}

output "dgpdb2_dbhome_id" {
  value = oci_database_db_home.dgpdb2.id
}

output "dgpdb1_database_id" {
  value = oci_database_database.dgpdb1.id
}

output "dgpdb2_database_id" {
  value = oci_database_database.dgpdb2.id
}
