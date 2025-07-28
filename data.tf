data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_default_service_account" "nodes" {
  project = var.project_id
}
