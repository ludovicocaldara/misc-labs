data "oci_identity_compartment" "my_compartment" {
    id = var.compartment_ocid
}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "vm_images" {
  compartment_id             = var.compartment_ocid
  display_name               = "Oracle-Linux-8.4-2021.08.27-0"
}
