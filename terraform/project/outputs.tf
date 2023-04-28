output "project_id" {
  description = "Project ID"
  value       = module.project.project_id
}

output "site_storage_bucket_name" {
  description = "Name of GCS bucket where site is hosted."
  value       = google_storage_bucket.my-site.name
}