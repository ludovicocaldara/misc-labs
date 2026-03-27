terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
    }
  }
}

provider "oci" {
  region = var.region
}