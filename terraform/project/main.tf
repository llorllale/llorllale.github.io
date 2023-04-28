locals {
  organization_id    = "" # no org
  billing_account_id = "012E33-751ED1-6E8DF0"
}

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.2"

  org_id = local.organization_id

  name              = "My Site"
  project_id        = "my-site"
  random_project_id = true
  billing_account   = local.billing_account_id
}

resource "google_storage_bucket" "state" {
  name                        = "my-site-tf-state"
  project                     = module.project.project_id
  location                    = "NORTHAMERICA-NORTHEAST2"
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}