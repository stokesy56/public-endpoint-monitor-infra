terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.45.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

terraform {
  backend "gcs" {
    bucket = "public-endpoint-monitor-tfstate"
    prefix = "prod"
  }
}

locals {
  cluster_endpoint = google_container_cluster.autopilot.endpoint
  cluster_ca_cert = base64decode(
    google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  )
  auth_token = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    token                  = local.auth_token
    cluster_ca_certificate = local.cluster_ca_cert
  }
}

provider "kubernetes" {
  host                   = "https://${local.cluster_endpoint}"
  token                  = local.auth_token
  cluster_ca_certificate = local.cluster_ca_cert
}
