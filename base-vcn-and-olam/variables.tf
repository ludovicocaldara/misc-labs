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


variable "vcn_cidr" {
  description = "CIDR block for the VCN. Security rules are created after this."
  default = "10.0.0.0/16"
}

variable "admin_subnet_cidr" {
  description = "CIDR block for the subnet."
  default = "10.0.0.0/24"
}

variable "user_ocid" {
}

variable "ssh_public_key" {
}

variable "private_key_path" {
}

variable "fingerprint" {
}

locals {
 ssh_private_key = ""
 }
