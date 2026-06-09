variable "compartment_ocid" {
  description = "The OCID of the compartment you want to work with." 
}
variable "image_ocid" {
  description = "The OCID of the image you want to use for compute. get images with oci compute image list --compartment-id" 
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
  description = "OCI Compute VM shape. Flex is the new default and it's pretty nice :-). Beware of your quotas, credits and limits if you plan to change it. Always Free: VM.Standard.E2.1.Micro"
  default = "VM.Standard.E2.1.Micro"
}

variable "compute_name" {
  description = "display name for the compute instance"
  default = "demo-vm"
}

variable "boot_volume_size_in_gbs" {
  description = "Size in GB for compute instance boot volume"
  default = 128
}

variable "ocpus" {
  description = "The number of OCPUs to assign to the instance. Must be between 1 and 4."
  type        = number
  default     = 1

  validation {
    condition     = var.ocpus >= 1
    error_message = "The value of ocpus must be greater than or equal to 1."
  }

  validation {
    condition     = var.ocpus <= 2
    error_message = "The value of ocpus must be less than or equal to 2 to remain in the always free."
  }
}

variable "memory_in_gbs" {
  description = "The amount of memory in GB to assign to the instance. Must be between 1 and 24."
  default     = 2

  validation {
    condition     = var.memory_in_gbs >= 1
    error_message = "The value of memory_in_gbs must be greater than or equal to 1."
  }

  validation {
    condition     = var.memory_in_gbs <= 2
    error_message = "The value of memory_in_gbs must be less than or equal to 2 to remain in the always free."
  }
}
