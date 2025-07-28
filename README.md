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
## Bootstrap: remote state bucket & CI service-account

Terraform needs two cloud-side prerequisites *before* GitHub Actions can run:

1. **Versioned GCS bucket** for `terraform.tfstate`  
2. **Service account** that GitHub’s OIDC token can impersonate (plus IAM)

This repo ships with **`bootstrap.sh`** that creates **or** destroys those
prereqs for you.

| Mode | What it does |
|------|--------------|
| **`create`** *(default)* | • Creates `gs://<PROJECT>-tfstate` & turns **versioning on**<br>• Creates `tf-infra@<PROJECT>.iam.gserviceaccount.com`<br>• Grants SA project-wide **`roles/editor`** <br>• Ensures Workload-Identity **pool** `github-pool` and **provider** `github` exist (creates if absent)<br>• Adds **`roles/iam.workloadIdentityUser`** binding to allow repos:<br>&nbsp;&nbsp;`public-endpoint-monitor-app` and `public-endpoint-monitor-infra` to impersonate the SA |
| **`destroy`** | Removes that IAM binding, deletes the SA, **deletes the bucket (and state)**. Use with care! |

### Usage

```bash
# one-time setup
./bootstrap.sh create <PROJECT_ID> [REGION] [GH_OWNER] [INFRA_REPO] # last three options are optional

```

To tear everything down later:

```bash
./bootstrap.sh destroy <PROJECT_ID> [REGION] [GH_OWNER] [INFRA_REPO] # last three options are optional
```

The script is **idempotent** – running `create` again simply skips existing
objects and updates the provider’s repo allow-list.

---

### Next steps after running `create`

**Add GitHub secrets** to *both* repos:  

   | Secret | Value |
   |--------|-------|
   | `GCP_PROJECT` | `<PROJECT_ID>` |
   | `GCP_PROVIDER` | Full provider path, e.g.<br>`projects/<project number>/locations/global/workloadIdentityPools/<workload-pool>/providers/github` |

