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

data "http" "platform_app" {
  url = "https://raw.githubusercontent.com/${var.github_repository_argo}/main/platform/applications.yaml"
}

data "http" "pem_applicationset" {
  url = "https://raw.githubusercontent.com/${var.github_repository_argo}/main/platform/pem-applicationset.yaml"
}