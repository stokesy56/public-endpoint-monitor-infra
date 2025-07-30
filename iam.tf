# github app repo ci service account
resource "google_service_account" "ci_sa" {
  project      = var.project_id
  account_id   = var.service_account_id_ci
  display_name = var.service_account_name_ci
}

resource "google_project_iam_member" "ci_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci_sa.email}"
}

resource "google_service_account_iam_member" "ci_wi_user" {
  service_account_id = google_service_account.ci_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${data.google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
}

resource "google_project_iam_member" "nodes_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_compute_default_service_account.nodes.email}"
}
# argo CD service account
resource "google_service_account" "pem_argo_reader" {
  project      = var.project_id
  account_id   = var.service_account_id_argo
  display_name = var.service_account_name_argo
}

resource "google_project_iam_member" "pem_argo_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.pem_argo_reader.email}"
}


resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.pem_argo_reader.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-repo-server]"
}
