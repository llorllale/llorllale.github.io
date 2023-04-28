data "terraform_remote_state" "project_state" {
  backend = "gcs"
  config = {
    bucket = "my-site-tf-state"
    prefix = "state/project"
  }
}

resource "google_service_account" "service_account" {
  project      = data.terraform_remote_state.project_state.outputs.project_id
  account_id   = "github-cd-sa"
  display_name = "GitHub CD Service Account"
}

resource "google_project_iam_member" "service_account" {
  project = data.terraform_remote_state.project_state.outputs.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
