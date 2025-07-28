#!/usr/bin/env bash
# bootstrap.sh  —  create or destroy Terraform backend + CI SA

# Usage:
#   ./bootstrap.sh create  <PROJECT_ID> [REGION] [OWNER] [REPO]
#   ./bootstrap.sh destroy <PROJECT_ID> [REGION] [OWNER] [REPO]

set -euo pipefail

# ── arguments ────────────────────────────────────────────────────────────────
CMD=${1:-create}
PROJECT_ID=${2:? "PROJECT_ID required"}
REGION=${3:-europe-west2}
OWNER=${4:-stokesy56}
REPO=${5:-public-endpoint-monitor-infra}

BUCKET="${PROJECT_ID}-tfstate"
SA_EMAIL="tf-infra@${PROJECT_ID}.iam.gserviceaccount.com"
POOL_ID="github-pool"
PROVIDER_ID="github"

gcloud config set project "$PROJECT_ID" >/dev/null

PROJECT_NUM=$(gcloud projects describe "$PROJECT_ID" \
               --format='value(projectNumber)')
WIP_PATH="projects/${PROJECT_NUM}/locations/global/workloadIdentityPools/${POOL_ID}"

# ── helper -------------------------------------------------------------------
confirm() {
  read -r -p "Continue? [y/N] " ans
  [[ $ans == y || $ans == Y ]]
}

# ── create -------------------------------------------------------------------
if [[ $CMD == "create" ]]; then
  echo "Creating GCS bucket gs://$BUCKET (versioned)…"
  gsutil mb -p "$PROJECT_ID" -l "$REGION" gs://"$BUCKET" 2>/dev/null || true
  gsutil versioning set on gs://"$BUCKET"

  echo "Creating service account $SA_EMAIL…"
  gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1 || \
  gcloud iam service-accounts create tf-infra \
    --display-name "Terraform infra CI"

  echo "Granting roles/editor and Storage Object Admin…"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" --role="roles/editor" --quiet
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" --role="roles/resourcemanager.projectIamAdmin" --quiet
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" --role="roles/iam.serviceAccountAdmin" --quiet
  gsutil iam ch serviceAccount:"$SA_EMAIL":objectAdmin gs://"$BUCKET"

if ! gcloud iam workload-identity-pools describe ${POOL_ID} --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create ${POOL_ID} \
    --location=global \
    --display-name="GitHub OIDC pool"
else
  echo "github-pool already exists - skipping create"
fi

if ! gcloud iam workload-identity-pools providers describe github \
     --location=global --workload-identity-pool=${POOL_ID} >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc github \
    --location=global \
    --workload-identity-pool=${POOL_ID} \
    --display-name="GitHub provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository in ['${OWNER}/public-endpoint-monitor-app','${OWNER}/public-endpoint-monitor-infra']"
else
  echo "provider exists - updating attribute-condition"
  gcloud iam workload-identity-pools providers update-oidc github \
    --location=global \
    --workload-identity-pool=${POOL_ID} \
    --attribute-condition="assertion.repository in ['${OWNER}/public-endpoint-monitor-app','${OWNER}/public-endpoint-monitor-infra']"
fi

  echo "Adding Workload Identity binding for GitHub repo…"
  gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/${WIP_PATH}/attribute.repository/${OWNER}/${REPO}" --quiet

  echo "Bootstrap complete."
  exit 0
fi

# ── destroy ------------------------------------------------------------------
if [[ $CMD == "destroy" ]]; then
  echo "This will REMOVE the tfstate bucket, service account, and IAM bindings."
  confirm || { echo "Aborted."; exit 1; }

  echo "Removing Workload Identity binding…"
  gcloud iam service-accounts remove-iam-policy-binding "$SA_EMAIL" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/${WIP_PATH}/attribute.repository/${OWNER}/${REPO}" --quiet || true

  echo "Deleting service account $SA_EMAIL…"
  gcloud iam service-accounts delete "$SA_EMAIL" --quiet || true

  echo "Deleting bucket gs://$BUCKET (and objects)…"
  gsutil -m rm -r gs://"$BUCKET" || true

  echo "Cleanup finished."
  exit 0
fi

echo "Usage: $0 [create|destroy] <PROJECT_ID> [REGION] [OWNER] [REPO]"
exit 1
