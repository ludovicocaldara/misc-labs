# ----------------------------------
# Tenancy and landing zone inputs
# ----------------------------------

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where the lab resources are created."
}

variable "landing_zone_name" {
  type        = string
  description = "Name of the landing zone (used to reference baseline resources)."
  default = "lab-lz"
}

variable "region" {
  type        = string
  description = "OCI region where resources will be provisioned."
}

variable "tenancy_ocid" { type = string }

variable "lab_number" {
  type        = number
  description = "Number of the lab (used calculate the subnet CIDR (e.g. 10.50.lab_number.0/24) and eventually to create unique resource names)."
}

variable "defined_tags"  {
  type = map(string)
  default = {}
}
variable "freeform_tags" {
  type = map(string)
  default = {}
}

# ----------------------------------
# Database system configuration
# ----------------------------------

variable "lab_name" {
  type        = string
  default     = "adghol"
  description = "Short name used to prefix resource names."
}

variable "pdb_name" {
  type        = string
  default     = "mypdb"
  description = "Name of the PDB created inside each DB system."
}

variable "ad_number" {
  type        = number
  default     = 1
  description = "Availability domain number where the DB systems will be created."
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Nodes per DB system. Keep to 1 for single-instance systems."
}

variable "db_system_count" {
  type        = number
  default     = 1
  description = "Number of standalone DB systems to provision."
}

variable "cpu_core_count" {
  type        = number
  default     = 2
  description = "CPU cores per DB system node."
}

variable "data_storage_size_in_gb" {
  type        = number
  default     = 256
  description = "Total data storage (in GB) available to the DB system."
}

variable "data_storage_percentage" {
  type        = number
  default     = 80
  description = "Percentage of total storage allocated to data disks."
}

variable "db_shape" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "Compute shape for the DB systems."
}

variable "db_version" {
  type        = string
  default     = "23.26.1.0.0"
  description = "Database software version. This lab targets 23ai."
}

variable "db_edition" {
  type        = string
  default     = "ENTERPRISE_EDITION_EXTREME_PERFORMANCE"
  description = "Database edition for the DB system."
}

variable "storage_management" {
  type        = string
  default     = "LVM"
  description = "Storage management option (LVM or ASM)."
}

variable "license_model" {
  type        = string
  default     = "BRING_YOUR_OWN_LICENSE"
  description = "License model for the DB system."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key injected into the DB systems."
}

variable "db_admin_password" {
  type        = string
  sensitive   = true
  description = "Password for the SYS/SYSTEM accounts. Provide via tfvars or environment variable."
}

locals {
  tags_freeform = merge({ "stack" = var.lab_name }, var.freeform_tags)
}
