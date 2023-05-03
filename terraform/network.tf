## NOTE: Must go manually into Cloud Domains console and register the domain.
##       Terraform does not yet support doing this for a host of reasons - see
##       https://github.com/hashicorp/terraform-provider-google/issues/7696.

locals {
  root_domain_name = "georgearisty.dev."
}

#################################### HTTP(S) Load Balancer ########################################
resource "google_compute_global_address" "public_ip" {
  name    = "public-ip"
  project = module.project.project_id
}

resource "google_compute_backend_bucket" "my_site_bucket_backend" {
  project     = module.project.project_id
  name        = "my-site-bucket-backend"
  bucket_name = google_storage_bucket.my_site.name
  #  enable_cdn  = true
}

resource "google_compute_url_map" "site_url_map" {
  project         = module.project.project_id
  name            = google_storage_bucket.my_site.name
  default_service = google_compute_backend_bucket.my_site_bucket_backend.id
}

resource "google_compute_managed_ssl_certificate" "cert" {
  name    = "my-site-cert"
  project = module.project.project_id

  managed {
    domains = [google_dns_record_set.dns_site_record.name]
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project          = module.project.project_id
  name             = "https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
  url_map          = google_compute_url_map.site_url_map.id
  quic_override    = "ENABLE"
}

resource "google_compute_global_forwarding_rule" "https_proxy_forwarding_rule" {
  project               = module.project.project_id
  name                  = "https-proxy-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.public_ip.id
}

# HTTP->HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  project = module.project.project_id
  name    = "http-redirect"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT" // 301 redirect
    strip_query            = false
    https_redirect         = true
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name    = "http-redirect"
  project = module.project.project_id
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  project    = module.project.project_id
  name       = "http-redirect"
  target     = google_compute_target_http_proxy.http_redirect.id
  ip_address = google_compute_global_address.public_ip.id
  port_range = "80"
}

############################################### DNS ###############################################
resource "google_dns_managed_zone" "public_zone" {
  name       = "public-zone"
  project    = module.project.project_id
  visibility = "public"

  dns_name    = local.root_domain_name
  description = "My Site DNS zone"
  #  dnssec_config {} TODO
}

resource "google_dns_record_set" "dns_site_record" {
  project = module.project.project_id
  name    = google_dns_managed_zone.public_zone.dns_name
  type    = "A"
  ttl     = 3600

  managed_zone = google_dns_managed_zone.public_zone.name

  rrdatas = [google_compute_global_address.public_ip.address]
}
