# Must create the key manually to download the private parts

resource "google_service_account" "github" {
  project = module.project.project_id

  account_id   = "github"
  display_name = "GitHub CD Service Account"
}

resource "google_storage_bucket_iam_member" "github" {
  bucket = google_storage_bucket.my-site.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github.email}"
}
