module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.2"

  org_id = var.organization_id

  name              = "My Site"
  project_id        = "my-site"
  random_project_id = true
  billing_account   = var.billing_account_id

  activate_apis = [
    "dns.googleapis.com",
    "compute.googleapis.com",
    "domains.googleapis.com"
  ]
}
