data "oci_core_images" "vm_images" {
  compartment_id             = var.compartment_id
  operating_system           = "Oracle Linux"
  operating_system_version   = "8"
  sort_by                    = "TIMECREATED"
  sort_order                 = "DESC"
  shape                      = var.vm_shape
}

data "oci_core_image_shapes" "vm_shapes" {
  image_id = data.oci_core_images.vm_images.images[0].id
}

