# public-endpoint-monitor – Infrastructure as Code

Terraform definitions for **all Google Cloud resources** used by the\
[public-endpoint-monitor](https://github.com/stokesy56/public-endpoint-monitor-app) application:

| Layer | Resources created / imported |
|-------|------------------------------|
| **Container registry** | Artifact Registry _public-endpoint-monitor_ (Docker + OCI charts) |
| **CI Federation** | Workload-Identity Pool **`gh-oidc-pool`** + Provider **`github`** |
|                    | Service-account **`ci-build@…`**, IAM bindings for:<br>• `roles/artifactregistry.writer` (Project) <br>• `roles/iam.workloadIdentityUser` (SA) |
| **Runtime** | GKE **Autopilot** cluster **`pem-auto`** (regional) |

---

## Deploy
```bash
terraform init
terraform fmt
tflint --init && tflint
terraform plan
tarraform apply
```
