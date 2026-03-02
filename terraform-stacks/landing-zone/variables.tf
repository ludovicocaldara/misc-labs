variable "tenancy_ocid" { type = string }
variable "region" { type = string }

variable "compartment_ocid" { type = string }

variable "name_prefix" {
   type = string
   default = "lab-lz"
}

variable "vcn_cidr" {
  type = string
  default = "10.50.0.0/16"
}

variable "bastion_subnet_cidr" {
  type    = string
  default = "10.50.1.0/24"
}

variable "enable_nat_gateway" {
  type = bool
  default = true
}

variable "enable_service_gateway" {
  type = bool
  default = true
}

variable "client_cidr_block_allow_list" {
  type        = list(string)
  description = "Public egress CIDRs allowed to initiate Bastion sessions (e.g., corporate VPN/NAT)."
}

variable "defined_tags"  {
  type = map(string)
  default = {}
}

variable "freeform_tags" {
  type = map(string)
  default = {stack = "landing-zone"}
}
