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
  default     = "lab-lz"
}

variable "region" {
  type        = string
  description = "OCI region where resources will be provisioned."
}

variable "tenancy_ocid" { type = string }

variable "landing_zone_subnet_name" {
  type        = string
  default     = "lab-lz-subnet-bastion-endpoint"
  description = "Display name of the existing landing-zone subnet where compute instances are placed. Public IP assignment is enabled only if this subnet allows public IPs."
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

# ----------------------------------
# Compute system configuration
# ----------------------------------

variable "lab_name" {
  type        = string
  default     = "adghol"
  description = "Short name used to prefix resource names."
}

variable "ad_number" {
  type        = number
  default     = 1
  description = "Availability domain number where the compute instances will be created."
}

variable "num_compute" {
  type        = number
  default     = 2
  description = "Number of compute instances to provision."
}

variable "compute_shape" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "Compute shape for the instances."
}

variable "shape_ocpus" {
  type        = number
  default     = 2
  description = "OCPUs for flex compute shapes."
}

variable "shape_memory_in_gbs" {
  type        = number
  default     = 16
  description = "Memory in GBs for flex compute shapes."
}

variable "image_ocid" {
  type        = string
  default     = ""
  description = "Optional custom image OCID. If empty, latest Oracle Linux image is used."
}

variable "image_operating_system" {
  type        = string
  default     = "Oracle Linux"
  description = "Operating system used when resolving default image."
}

variable "image_operating_system_version" {
  type        = string
  default     = "8"
  description = "Operating system version used when resolving default image."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key injected into the compute instances."
}

variable "bastion_allowed_tcp_ports_csv" {
  type        = string
  default     = "22"
  description = "Comma-separated list of TCP destination ports to allow from bastion endpoint subnet (example: 22,1521,3389)."
}

locals {
  tags_freeform = merge({ "stack" = var.lab_name }, var.freeform_tags)
}
