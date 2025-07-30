resource "helm_release" "argocd" {
  name             = var.helm_id
  namespace        = var.helm_id
  create_namespace = true
  force_update     = true
  atomic           = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = var.helm_chart
  version    = var.helm_version

  values = [
    file("${path.module}/values/argocd-values.yaml"),

    yamlencode({
      crds = {
        install = true
      }

      applicationSet = {
        enabled     = true
        installCRDs = true
      }

      repoServer = {
        serviceAccount = {
          annotations = {
            "iam.gke.io/gcp-service-account" = google_service_account.pem_argo_reader.email
          }
        }
      }

      configs = {
        repositories = {
          "public-endpoint-monitor-registry" = {
            url       = "europe-west2-docker.pkg.dev/${var.project_id}/${var.registry_name}"
            type      = "helm"
            enableOCI = "true"
          },
          "github repository" = {
            url  = "https://github.com/${var.github_repository_argo}.git"
            type = "git"
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_cluster_role_binding.tf_infra_cluster_admin]
}

resource "kubernetes_cluster_role_binding" "tf_infra_cluster_admin" {
  metadata {
    name = "tf-infra-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    api_group = "rbac.authorization.k8s.io"
    name      = "tf-infra@${var.project_id}.iam.gserviceaccount.com"
  }

  depends_on = [google_container_cluster.autopilot]
}