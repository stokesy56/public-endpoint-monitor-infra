resource "google_container_cluster" "autopilot" {
  name                = var.cluster_name
  location            = var.region
  enable_autopilot    = true
  networking_mode     = "VPC_NATIVE"
  deletion_protection = false

  node_locations = ["europe-west2-a", "europe-west2-b"]

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "STABLE"
  }
}


resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region
  repository_id = var.registry_name
  format        = "DOCKER"
}
