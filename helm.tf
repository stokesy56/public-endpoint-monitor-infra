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

      repoServer = {
        serviceAccount = {
          create = true
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
          "github-repository" = {
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

resource "kubectl_manifest" "app-of-apps" {
  depends_on = [helm_release.argocd]
  yaml_body  = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-root
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/stokesy56/public-endpoint-monitor-gitops.git
    targetRevision: main
    path: apps
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
YAML
}
