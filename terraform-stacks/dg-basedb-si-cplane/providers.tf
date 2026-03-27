terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.30"
    }
  }
}

provider "oci" {
  region = var.region
}