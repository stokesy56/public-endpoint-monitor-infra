data "google_project" "project" {
  project_id = var.project_id
}

data "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = var.identity_pool_id
}

data "google_client_config" "default" {}

data "google_project" "current" {}