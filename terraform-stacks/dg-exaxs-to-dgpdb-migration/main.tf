terraform {
  required_version = ">= 1.5.0"

}

provider "oci" {
  region = var.region
}

# -----------------
# Variables
# -----------------

variable "region" {
  description = "OCI region (e.g., us-phoenix-1)"
  type        = string
  default     = "us-phoenix-1"
}

variable "compartment_ocid" {
  description = "Target compartment OCID"
  type        = string
}

variable "availability_domain" {
  description = "AD for ExaDB-XS resources (e.g., PHX-AD-1)"
  type        = string
}

# Networking CIDRs
variable "vcn_cidr" {
  description = "VCN CIDR"
  type        = string
  default     = "10.40.0.0/16"
}

# (Client subnet removed by design — VM Clusters will use the PUBLIC subnet)
variable "backup_subnet_cidr" {
  description = "Backup (private) subnet CIDR"
  type        = string
  default     = "10.40.2.0/24"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR (used by both VM Clusters)"
  type        = string
  default     = "10.40.10.0/24"
}

# Vault capacity
variable "vault_highcap_size_gb" {
  description = "Total High Capacity storage (GiB) in the Exascale Storage Vault"
  type        = number
  default     = 500
}

# Cluster config
variable "ssh_public_key" {
  description = "OpenSSH public key to inject to cluster nodes (optional)"
  type        = string
  default     = null
}

variable "grid_image_id" {
  description = "Optional Grid Infrastructure image OCID override for ExaDB-XS (DB Patch OCID, e.g., ocid1.dbpatch...). When null/empty, Terraform discovers the image from gi_version in availability_domain."
  type        = string
  default     = null
}

variable "gi_version" {
  description = "Grid Infrastructure major version used to discover the ExaDB-XS grid image OCID."
  type        = string
  default     = "23.0.0.0"
}

variable "enabled_ecpu_per_node" {
  description = "Enabled ECPUs per node (XS)."
  type        = number
  default     = 8
}

variable "total_ecpu_per_node" {
  description = "Total ECPUs per node (cap)."
  type        = number
  default     = 8
}

variable "vmfs_size_gb_per_node" {
  description = "VM filesystem storage per node (GiB)."
  type        = number
  default     = 250
}

# DB settings
variable "db_version" {
  description = "Database version label (e.g., 23ai)"
  type        = string
  default     = "23.26.2.0.0"
}

variable "db_name" {
  description = "CDB name for RAC DB 1, the primary database in the Data Guard group."
  type        = string
  default     = "racdb1"
}

variable "db2_name" {
  description = "CDB name for RAC DB 2, the independent database on Cluster A."
  type        = string
  default     = "racdb2"
}

variable "db4_name" {
  description = "CDB name for RAC DB 4, the independent database on Cluster B."
  type        = string
  default     = "racdb4"
}

variable "pdb_name" {
  description = "PDB name"
  type        = string
  default     = "mypdb"
}

variable "db_admin_password" {
  description = "SYS/ADMIN password for the CDB"
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

variable "enable_active_data_guard" {
  description = "Enable Active Data Guard (read-only standby)."
  type        = bool
  default     = true
}

# Timing knobs (tune if service is busy)
variable "post_cluster_wait_seconds" {
  description = "Wait after clusters provision before creating DB Homes (helps avoid transient 500s)."
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
# Networking (VCN, IGW, NAT, Service Gateway, subnets)
# -----------------

resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "exadb-xs-vcn"
  dns_label      = "exadbvcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-igw"
}

resource "oci_core_nat_gateway" "ngw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-ngw"
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
  osn_service      = one([for s in data.oci_core_services.osn.services : s])
  osn_service_id   = local.osn_service.id
  osn_service_cidr = local.osn_service.cidr_block
}

locals {
  provided_grid_image_id       = var.grid_image_id == null ? "" : trimspace(var.grid_image_id)
  use_discovered_grid_image_id = local.provided_grid_image_id == ""
}

data "oci_database_gi_version_minor_versions" "exadb_xs" {
  count = local.use_discovered_grid_image_id ? 1 : 0

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  shape_family        = "EXADB_XS"
  version             = var.gi_version
}

locals {
  discovered_grid_image_id = local.use_discovered_grid_image_id ? lookup(data.oci_database_gi_version_minor_versions.exadb_xs[0].gi_minor_versions[0], "grid_image_id") : null
  effective_grid_image_id  = local.provided_grid_image_id != "" ? local.provided_grid_image_id : local.discovered_grid_image_id
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-sgw"

  services {
    service_id = local.osn_service_id
  }
}

resource "oci_core_route_table" "rt_public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-rt-public"

  route_rules {
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "rt_private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "exadb-xs-rt-private"

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
  display_name   = "exadb-xs-sl-common"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # SSH
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Oracle listener
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 1521
      max = 1521
    }
  }

  # EM Express
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 5500
      max = 5500
    }
  }
}

# PUBLIC subnet (used by both VM Clusters)
resource "oci_core_subnet" "subnet_public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "exadb-xs-public-subnet"
  route_table_id             = oci_core_route_table.rt_public.id
  security_list_ids          = [oci_core_security_list.sl_common.id]
  prohibit_public_ip_on_vnic = false
  dns_label                  = "public"
}

# BACKUP subnet (private)
resource "oci_core_subnet" "subnet_backup" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  cidr_block                 = var.backup_subnet_cidr
  display_name               = "exadb-xs-backup-subnet"
  route_table_id             = oci_core_route_table.rt_private.id
  security_list_ids          = [oci_core_security_list.sl_common.id]
  prohibit_public_ip_on_vnic = true
  dns_label                  = "backup"
}

# -----------------
# Shared Exascale Storage Vault
# -----------------

resource "oci_database_exascale_db_storage_vault" "vault" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "exadb-xs-vault"

  high_capacity_database_storage {
    total_size_in_gbs = var.vault_highcap_size_gb
  }
}

# -----------------
# Two ExaDB‑XS VM Clusters (in PUBLIC subnet)
# -----------------

resource "oci_database_exadb_vm_cluster" "cluster_a" {
  compartment_id               = var.compartment_ocid
  availability_domain          = var.availability_domain
  subnet_id                    = oci_core_subnet.subnet_public.id
  backup_subnet_id             = oci_core_subnet.subnet_backup.id
  exascale_db_storage_vault_id = oci_database_exascale_db_storage_vault.vault.id

  display_name    = "exadb-xs-cluster-a"
  cluster_name    = "exadbxsa"
  hostname        = "exadbxsa"
  shape           = "ExaDbXS"
  ssh_public_keys = var.ssh_public_key == null ? [] : [var.ssh_public_key]
  grid_image_id   = local.effective_grid_image_id
  license_model   = "BRING_YOUR_OWN_LICENSE"

  node_config {
    enabled_ecpu_count_per_node              = var.enabled_ecpu_per_node
    total_ecpu_count_per_node                = var.total_ecpu_per_node
    vm_file_system_storage_size_gbs_per_node = var.vmfs_size_gb_per_node
  }

  # Define 2 nodes for RAC
  node_resource {
    node_name = "node1"
  }
  node_resource {
    node_name = "node2"
  }

  timeouts {
    create = "6h"
    update = "6h"
    delete = "6h"
  }
}


resource "oci_database_exadb_vm_cluster" "cluster_b" {
  compartment_id               = var.compartment_ocid
  availability_domain          = var.availability_domain
  subnet_id                    = oci_core_subnet.subnet_public.id
  backup_subnet_id             = oci_core_subnet.subnet_backup.id
  exascale_db_storage_vault_id = oci_database_exascale_db_storage_vault.vault.id

  display_name    = "exadb-xs-cluster-b"
  cluster_name    = "exadbxsb"
  hostname        = "exadbxsb"
  shape           = "ExaDbXS"
  ssh_public_keys = var.ssh_public_key == null ? [] : [var.ssh_public_key]
  grid_image_id   = local.effective_grid_image_id
  license_model   = "BRING_YOUR_OWN_LICENSE"

  node_config {
    enabled_ecpu_count_per_node              = var.enabled_ecpu_per_node
    total_ecpu_count_per_node                = var.total_ecpu_per_node
    vm_file_system_storage_size_gbs_per_node = var.vmfs_size_gb_per_node
  }

  # Define 2 nodes for RAC
  node_resource {
    node_name = "node1"
  }
  node_resource {
    node_name = "node2"
  }

  timeouts {
    create = "6h"
    update = "6h"
    delete = "6h"
  }
}


# -----------------
# Wait after clusters, then build DB layer (serialized)
# -----------------

resource "time_sleep" "post_clusters" {
  create_duration = "${var.post_cluster_wait_seconds}s"

  depends_on = [
    oci_database_exadb_vm_cluster.cluster_a,
    oci_database_exadb_vm_cluster.cluster_b
  ]
}

# DB Home for RAC DB 1 on Cluster A
resource "oci_database_db_home" "dbhome_db1" {
  display_name  = "exadbxs-db1-home"
  db_version    = var.db_version
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = oci_database_exadb_vm_cluster.cluster_a.id

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [
    time_sleep.post_clusters
  ]
}

# Gap between homes
resource "time_sleep" "after_dbhome_db1" {
  create_duration = "${var.between_dbhomes_wait_seconds}s"
  depends_on      = [oci_database_db_home.dbhome_db1]
}

# DB Home for RAC DB 2 on Cluster A
resource "oci_database_db_home" "dbhome_db2" {
  display_name  = "exadbxs-db2-home"
  db_version    = var.db_version
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = oci_database_exadb_vm_cluster.cluster_a.id

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [
    time_sleep.after_dbhome_db1
  ]
}

resource "time_sleep" "after_dbhome_db2" {
  create_duration = "${var.between_dbhomes_wait_seconds}s"
  depends_on      = [oci_database_db_home.dbhome_db2]
}

# DB Home for RAC DB 3, the physical standby on Cluster B
resource "oci_database_db_home" "dbhome_db3" {
  display_name  = "exadbxs-db3-home"
  db_version    = var.db_version
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = oci_database_exadb_vm_cluster.cluster_b.id

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [
    time_sleep.after_dbhome_db2
  ]
}

resource "time_sleep" "after_dbhome_db3" {
  create_duration = "${var.between_dbhomes_wait_seconds}s"
  depends_on      = [oci_database_db_home.dbhome_db3]
}

# DB Home for RAC DB 4 on Cluster B
resource "oci_database_db_home" "dbhome_db4" {
  display_name  = "exadbxs-db4-home"
  db_version    = var.db_version
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = oci_database_exadb_vm_cluster.cluster_b.id

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [
    time_sleep.after_dbhome_db3
  ]
}

# Gap before DB create
resource "time_sleep" "pre_database" {
  create_duration = "${var.pre_database_wait_seconds}s"
  depends_on = [
    oci_database_db_home.dbhome_db1,
    oci_database_db_home.dbhome_db2,
    oci_database_db_home.dbhome_db3,
    oci_database_db_home.dbhome_db4
  ]
}

# RAC DB 1: primary database in the Data Guard group
resource "oci_database_database" "db1_primary" {
  db_home_id = oci_database_db_home.dbhome_db1.id
  source     = "NONE" # required when creating a fresh DB in an existing DB Home

  database {
    db_name        = var.db_name
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

  depends_on = [
    time_sleep.pre_database
  ]
}

# RAC DB 2: independent database on Cluster A
resource "oci_database_database" "db2_independent" {
  db_home_id = oci_database_db_home.dbhome_db2.id
  source     = "NONE"

  database {
    db_name        = var.db2_name
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

  depends_on = [
    time_sleep.pre_database
  ]
}

# RAC DB 3: physical standby for RAC DB 1
resource "oci_database_database" "db3_standby" {
  db_home_id = oci_database_db_home.dbhome_db3.id
  source     = "DATAGUARD"

  database {
    database_admin_password      = var.db_admin_password
    db_unique_name               = "${var.db_name}_site2"
    source_database_id           = oci_database_database.db1_primary.id
    protection_mode              = "MAXIMUM_PERFORMANCE"
    transport_type               = "ASYNC"
    is_active_data_guard_enabled = var.enable_active_data_guard
  }

  timeouts {
    create = "4h"
    update = "4h"
    delete = "4h"
  }

  depends_on = [
    oci_database_database.db1_primary
  ]
}

# RAC DB 4: independent database on Cluster B
resource "oci_database_database" "db4_independent" {
  db_home_id = oci_database_db_home.dbhome_db4.id
  source     = "NONE"

  database {
    db_name        = var.db4_name
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

  depends_on = [
    time_sleep.pre_database
  ]
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

output "dbhome_db1_id" {
  value = oci_database_db_home.dbhome_db1.id
}

output "dbhome_db2_id" {
  value = oci_database_db_home.dbhome_db2.id
}

output "dbhome_db3_id" {
  value = oci_database_db_home.dbhome_db3.id
}

output "dbhome_db4_id" {
  value = oci_database_db_home.dbhome_db4.id
}

output "db1_primary_id" {
  value = oci_database_database.db1_primary.id
}

output "db2_independent_id" {
  value = oci_database_database.db2_independent.id
}

output "db3_standby_id" {
  value = oci_database_database.db3_standby.id
}

output "db4_independent_id" {
  value = oci_database_database.db4_independent.id
}

output "data_guard_group" {
  value = oci_database_database.db1_primary.data_guard_group
}
