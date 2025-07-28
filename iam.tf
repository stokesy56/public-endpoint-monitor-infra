resource "google_iam_workload_identity_pool" "gh_pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.identity_pool_id
  display_name              = var.identity_pool_name
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.gh_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.identity_pool_provider_id
  display_name                       = var.identity_pool_provider_name

  oidc {
    issuer_uri = var.oidc_uri
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"
}


resource "google_service_account" "ci_sa" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = var.service_account_name
}

resource "google_project_iam_member" "ci_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci_sa.email}"
}

resource "google_service_account_iam_member" "ci_wi_user" {
  service_account_id = google_service_account.ci_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gh_pool.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
}

resource "google_project_iam_member" "nodes_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_compute_default_service_account.nodes.email}"
}
