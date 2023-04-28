terraform {
  required_version = ">= 1.4.0"
  backend "gcs" {
    bucket = "my-site-tf-state"
    prefix = "state/project"
  }
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
