data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_default_service_account" "nodes" {
  project = var.project_id
}

data "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = var.identity_pool_id
}

data "google_client_config" "default" {}

data "http" "app" {
  url = "https://raw.githubusercontent.com/${var.github_repository_argo}/refs/heads/main/platform/pem-dev-app.yaml"
}
