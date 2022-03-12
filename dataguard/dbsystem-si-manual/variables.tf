# ----------------------------------
# Tenancy information
# ----------------------------------
variable "compartment_ocid" {
  description = "Your compartment OCID, eg: \"ocid1.compartment.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\""
}
variable "tenancy_ocid" {
  description = "Your tenancy OCID, eg: \"ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\""
}
variable "region" {
  description = "Your region, eg: \"uk-london-1\""
}


variable "db_subnet_cidr" {
  description = "CIDR block for the subnet."
  default = "10.0.3.0/24"
}

variable "app_subnet_cidr" {
  description = "CIDR block for the subnet."
  default = "10.0.4.0/24"
}

variable "user_ocid" {
}

variable "ssh_public_key" {
}

variable "fingerprint" {
}

variable "private_key_path" {
}


locals {
  ssh_private_key = ""
}

variable "lab_name" {
}

# ----------------------------------------------------
# decent defaults:
# ----------------------------------------------------
variable "db_system_shape" {
  description = "DB system shape to use for the DB server."
  default = "VM.Standard2.2"
}

variable "vm_user" {
  description = "SSH user to connect to the server for the setup. Must have sudo privilege."
  default = "opc"
}

variable "node_count" {
  description = "Number of nodes in the Grid Infrastructure cluster. Use 1 for test and dev."
  default = "1"
}

variable "db_edition" {
  description = "Database edition. Must be EE-EP to use RAC, not mandatory for the server if 1 node setup."
  default = "ENTERPRISE_EDITION_EXTREME_PERFORMANCE"
}

# ----------------------------------------------------------
# we don't really care about the database being created,
# because we will use the system as server, not as DB server.
# But there are no ways to skip the database creation, so we'll just keep it.
#
# Note:
# there is no full layer 2 support in the OCI network.
# A full GI setup requires it (GI needs multicast), that's why we use DBCS and not a compute instance.
# ----------------------------------------------------------

variable "db_admin_password" {
  description = "Default sys/system password for the DB System database."
}

variable "n_character_set" {
  default = "AL16UTF16"
}

variable "character_set" {
  default = "AL32UTF8"
}

variable "db_workload" {
  default = "OLTP"
}

variable "db_disk_redundancy" {
  description = "ASM disk redundancy. Use HIGH for production, NORMAL otherwise."
  default = "NORMAL"
}

variable "db_version" {
  description = "Version for the DB system. This lab supports 19c, don't use 21c yet."
  default = "19.0.0.0"
}

variable "data_storage_size_in_gb" {
  description = "ASM space in GB. 256 is a good default to host also the Server storage."
  default = "256"
}

variable "license_model" {
  default = "BRING_YOUR_OWN_LICENSE"
}


locals {
  timestamp_full = timestamp()
  timestamp = replace(local.timestamp_full, "/[- TZ:]/", "")
}

locals {
  repo_script      = "/tmp/01_repo_setup.sh"
  dhclient_script  = "/tmp/dhclient.sh"
  dhclient_setup   = file("${path.root}/scripts/set-domain.sh")
}

