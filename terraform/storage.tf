resource "google_storage_bucket" "state" {
  name                        = "my-site-tf-state"
  project                     = module.project.project_id
  location                    = "NORTHAMERICA-NORTHEAST2"
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "my-site" {
  name                        = "george-aristy-my-site"
  project                     = module.project.project_id
  location                    = "NORTHAMERICA-NORTHEAST2"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_storage_bucket_iam_member" "owner" {
  bucket = google_storage_bucket.my-site.name
  role   = "roles/storage.admin"
  member = "user:${var.admin_email}"
}

resource "google_storage_bucket_iam_member" "public" {
  bucket = google_storage_bucket.my-site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
