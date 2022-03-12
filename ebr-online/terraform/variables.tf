variable "compartment_ocid" {
  description = "The OCID of the compartment you want to work with."
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN. Security rules are created after this."
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet."
  default = "10.0.0.0/24"
}

variable "vm_shape" {
  description = "OCI Compute VM shape. Flex is the new default and it's pretty nice :-). Beware of your quotas, credits and limits if you plan to change it."
  default = "VM.Standard2.2"
}

variable "compute_name" {
  description = "display name for the compute instance"
  default = "demo-vm"
}

variable "boot_volume_size_in_gbs" {
  description = "Size in GB for compute instance boot volume"
  default = 128
}

