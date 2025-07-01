# ----------------------------------
# Tenancy information
# ----------------------------------

variable "compartment_ocid" {}
variable "region" {}

variable "ssh_public_key" {
}

variable "db_edition" {
  default = "ENTERPRISE_EDITION_EXTREME_PERFORMANCE"
}

variable "db_admin_password" {
  description = "Default sys/system password for the DB System database."
  default = "WElcome123##"
}

variable "data_storage_size_in_gb" {
  description = "ASM space in GB. 256 is a good default to host also the Server storage."
  default = "256"
}

variable "license_model" {
  default = "BRING_YOUR_OWN_LICENSE"
}

variable "cpu_core_count" {
  default = "2"
}

variable "data_storage_percentage" {
  default = "80"
}

variable "db_shape" {
  default = "VM.Standard.E4.Flex"
}

variable "db_version" {
  default = "23.8.0.25.04"
  description = "Version for the DB system. This lab supports 23ai only."
}

variable "resId" {
  description = "A unique number to tell multiple labs apart. The subnet will use 10.0.resId.0/24 as CIDR, so use it carefully!"
  default = "79"
}

variable "node_count" {
  default = "1"
}
variable "members" {
  default = "2"
}
variable "storage_management" {
  default = "LVM" # ASM - Automatic storage management LVM - Logical Volume management
}
variable "lab_name" {
  default = "adghol"
}
variable "pdb_name" {
  default = "mypdb"
}
variable "ad_number" {
  default = "1"
}
