#!/bin/bash
# Dung ha tang GCP cho lab (Buoc 2.1 - 2.8). Chay tu thu muc goc cua repo bang Git Bash:
#   bash infra/setup-gcp.sh
# Script idempotent: chay lai se bo qua tai nguyen da ton tai.
set -euo pipefail

PROJECT=project-f7c2a130-32b1-4bad-afe
BUCKET=income-lab-diemvu-2a202602858
ZONE=us-central1-a
SA=income-lab-sa@$PROJECT.iam.gserviceaccount.com
DEPLOY_KEY=$HOME/.ssh/income_deploy
REPO=diemvu12369/K4-L3-Day21-VuMinhDiem-2A202602858-CI-CD-for-AI-Systems

echo "== 2.1 Bucket"
gcloud storage buckets describe gs://$BUCKET --format="value(name)" >/dev/null 2>&1 \
  || gcloud storage buckets create gs://$BUCKET --project $PROJECT --location us-central1 --uniform-bucket-level-access

echo "== 2.2 Service account (objectAdmin chi tren bucket)"
gcloud iam service-accounts describe $SA --project $PROJECT >/dev/null 2>&1 \
  || gcloud iam service-accounts create income-lab-sa --display-name "Income Lab SA" --project $PROJECT
gcloud storage buckets add-iam-policy-binding gs://$BUCKET \
  --member serviceAccount:$SA --role roles/storage.objectAdmin --format=none
[ -s sa-key.json ] || gcloud iam service-accounts keys create sa-key.json --iam-account $SA

echo "== 2.8 SSH key cho GitHub Actions"
mkdir -p "$HOME/.ssh"
[ -f "$DEPLOY_KEY" ] || ssh-keygen -t ed25519 -f "$DEPLOY_KEY" -N "" -C "github-actions-deploy"

echo "== 2.4 / 2.5 / 2.7 VM + firewall + systemd (qua startup-script)"
if ! gcloud compute instances describe income-api --zone $ZONE --project $PROJECT >/dev/null 2>&1; then
  gcloud compute instances create income-api \
    --zone=$ZONE --machine-type=e2-small \
    --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud \
    --tags=income-api --project $PROJECT \
    --service-account=$SA --scopes=cloud-platform \
    --metadata=artifact-bucket=$BUCKET,ssh-keys="deploy:$(cat "$DEPLOY_KEY.pub")" \
    --metadata-from-file=startup-script=infra/vm-startup.sh,serve-py=src/serve.py
fi
gcloud compute firewall-rules describe allow-income-api --project $PROJECT >/dev/null 2>&1 \
  || gcloud compute firewall-rules create allow-income-api --allow=tcp:8080 --target-tags=income-api --project $PROJECT

VM_IP=$(gcloud compute instances describe income-api --zone=$ZONE --project $PROJECT \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "== 2.3 dvc push"
for i in 1 2 3 4 5; do
  .venv/Scripts/dvc.exe push && break
  echo "dvc push that bai (IAM co the chua lan truyen), thu lai sau 20s..."; sleep 20
done

echo "== 2.9 GitHub Secrets"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh secret set STORAGE_CREDENTIALS -R $REPO < sa-key.json
  gh secret set ARTIFACT_BUCKET -R $REPO --body "$BUCKET"
  gh secret set SERVER_HOST -R $REPO --body "$VM_IP"
  gh secret set SERVER_USER -R $REPO --body "deploy"
  gh secret set SERVER_SSH_KEY -R $REPO < "$DEPLOY_KEY"
  gh secret list -R $REPO
else
  echo "Chua co gh CLI da dang nhap. Tu them 5 secrets tai Settings > Secrets and variables > Actions:"
  echo "  STORAGE_CREDENTIALS = noi dung file sa-key.json"
  echo "  ARTIFACT_BUCKET     = $BUCKET"
  echo "  SERVER_HOST         = $VM_IP"
  echo "  SERVER_USER         = deploy"
  echo "  SERVER_SSH_KEY      = noi dung file $DEPLOY_KEY"
fi

echo
echo "Xong. VM_IP=$VM_IP  (VM can ~3-5 phut de startup-script cai xong thu vien)"
