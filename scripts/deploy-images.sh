#!/usr/bin/env bash
set -euo pipefail
# Prereqs: AWS CLI v2, Docker, jq, terraform; run from repository root.
# First: terraform -chdir=infrastructure/terraform apply -target=aws_ecr_repository.employee -target=aws_ecr_repository.leave
cd "$(dirname "$0")/.."
TF="infrastructure/terraform"
REGION="$(terraform -chdir="$TF" output -raw aws_region 2>/dev/null || echo ap-south-1)"
EMP="$(terraform -chdir="$TF" output -raw ecr_employee)"
LEAVE="$(terraform -chdir="$TF" output -raw ecr_leave)"
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
TAG="${1:-v1}"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
for SERVICE in employee leave; do
  REPO="$EMP"; [[ "$SERVICE" == leave ]] && REPO="$LEAVE"
  docker build -f "$SERVICE-service/Dockerfile" -t "$REPO:$TAG" .
  docker push "$REPO:$TAG"
done
printf 'Pushed both container images with tag %s. Now run full terraform apply.\n' "$TAG"
