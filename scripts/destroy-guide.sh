#!/usr/bin/env bash
set -euo pipefail
# Deliberately interactive because this deletes the portfolio's AWS resources.
cd "$(dirname "$0")/.."
echo 'This will DELETE sample RDS data, files, Lambda, ECS, Cognito and other resources.'
read -r -p 'Type DESTROY-DEMO to proceed: ' answer
[[ "$answer" == DESTROY-DEMO ]] || { echo 'Cancelled.';exit 1; }
terraform -chdir=infrastructure/terraform destroy
# Check ECR, CloudWatch, Elastic IPs, S3, CodePipeline and costs in AWS Console after destroy.
