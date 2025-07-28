output "connect" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.autopilot.name} --region ${var.region} --project ${var.project_id}"
}