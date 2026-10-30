# Workforce Management — reusable AWS Terraform environment

This repository recreates the **architecture actually tested** in the Workforce AWS project, with per-environment names. It is intended as a starting infrastructure-as-code baseline; **it has not been applied to a live AWS account or validated against the downloaded provider in this environment**. Run `terraform fmt`, `terraform init`, `terraform validate`, and review `terraform plan` before applying.

## Architecture

Postman → **API Gateway HTTP API** (`ANY /{proxy+}`, Cognito JWT) → VPC Link → **internal ALB** (path routing) → Employee ECS/Fargate :8081 or Leave ECS/Fargate :8082 → two **MySQL schemas** on one private RDS MySQL instance. Employee uses private S3 bucket. Leave calls Employee through the **internal ALB DNS name** and publishes SQS events; Lambda processes the queue and uses DynamoDB for event deduplication. Images live in two ECR repositories; optional CodeBuild consumes your GitHub repository's existing `buildspec.yml`.

## Contents

- `network.tf`: VPC, 2 public and 2 private subnets, routing, SGs; optional NAT.
- `data.tf`: private RDS MySQL, Secrets Manager, S3, SQS + DLQ, DynamoDB, ECR, log groups.
- `identity.tf`: Cognito user pool, roles, public PKCE app client, Cognito domain and managed login branding.
- `alb.tf`: private ALB, Employee/Leave IP target groups, routes for `/api/leaves*` and `/api/attendance*`.
- `ecs.tf`: ECS Fargate cluster, Employee/Leave task definitions, service registrations, IAM-injected DB password.
- `api.tf`: HTTP API with JWT authorizer, greedy proxy, VPC Link and stage-path mapping.
- `lambda.tf`, `lambda/handler.py`: actual source project's Python SQS consumer and DynamoDB deduplication.
- `codebuild.tf`: optional GitHub CodeConnections authenticated CodeBuild project.
- `environments/`: staging and production example variables.

## Requirements

Terraform >= 1.6, AWS CLI authenticated with permissions to provision the resources, access to the AWS account, original `workforce-management-system` GitHub repo with Dockerfiles + `buildspec.yml`. The stack defaults to `us-east-2`. Use a dedicated AWS account for production if possible.

## Critical: do not apply this configuration to your existing manually created `workforce-*` resources

The resources in this project use **environment-prefixed names**, e.g. `workforce-staging-*`. This avoids altering your functioning Ohio deployment. If you want Terraform to manage the *existing* resources, first build an import plan with `terraform import` / `import` blocks, reconcile state and resource configurations, and perform `terraform plan` until it shows no unexpected changes. **Do not just apply against existing names.**

## Deployment sequence (PowerShell, Windows 11)

Make a **separate copy of the project folder per environment**, or use isolated state workspaces and separate variable files with strict review; do not reuse the same local Terraform state for staging and prod.

```powershell
cd workforce-terraform
Copy-Item environments/staging.tfvars.example staging.tfvars
$env:TF_VAR_db_password = 'SUPPLY_A_STRONG_PASSWORD_IN_YOUR_OWN_TERMINAL'
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file="staging.tfvars" -out="staging.tfplan"
terraform apply "staging.tfplan"
```

The initial `enable_services = false` creates AWS infrastructure, ECR, Cognito, Lambda, API Gateway, etc., **without starting ECS containers**. This is intentional to avoid deploying missing Docker images. Creating AWS resources incurs costs even when ECS is off (notably ALB and RDS).

### Build and push Docker images

1. Optionally set `github_repo_url` and an **already AVAILABLE** `codebuild_connection_arn` in `staging.tfvars`. GitHub's app authorization/connection handshake needs a one-time owner approval in AWS; Terraform cannot silently grant GitHub consent.
2. Build using the newly created CodeBuild project and the **existing original application's** `buildspec.yml`; that build pushes both images tagged with `CODEBUILD_RESOLVED_SOURCE_VERSION` (normally commit SHA). Or build/push images by another authenticated CI system.
3. Retrieve image tags in ECR. Update `employee_image_tag` and `leave_image_tag` to actual pushed tags (not placeholder values), and set `enable_services = true`.
4. Run `terraform plan` then `terraform apply` again. ECS tasks start, connect to the RDS endpoint, register in ALB target groups, and run Flyway migrations.

### Leave database schema caveat

The Terraform stack creates the RDS MySQL instance with database `workforce`. Your validated Ohio stack uses a **second schema** `workforce_leave` on that same instance. This baseline passes `SPRING_DATASOURCE_URL=jdbc:mysql://.../workforce_leave?createDatabaseIfNotExist=true` to Leave Service to match the temporary bootstrap approach that worked in your deployment. **Before production**, create the `workforce_leave` schema through an approved bootstrap migration or DBA action and remove `createDatabaseIfNotExist=true`; use separate restricted DB users per service. Terraform AWS provider does not directly model arbitrary MySQL schemas inside RDS.

### Cognito users / groups

The stack creates Cognito `HR`, `MANAGER`, `EMPLOYEE` groups but **does not create user passwords or assign real users**. Admin-create users in the new user pool and add them to groups, or integrate an appropriate identity lifecycle process. Postman has to authenticate against the **new** environment's Cognito issuer, client ID, and Cognito domain. The app client uses Authorization Code + PKCE, `openid email profile`, and the Postman callback URL.

### Confirm output endpoints

```powershell
terraform output api_base_url
terraform output cognito_domain
terraform output cognito_user_pool_id
terraform output cognito_client_id
terraform output sqs_queue_url
terraform output employee_ecr_repo
terraform output leave_ecr_repo
terraform output rds_endpoint
```

First smoke test: `GET <api_base_url>/api/employees` without token returns 401; with HR bearer access token returns 200 and an empty employee page. Create a test employee, record attendance, submit and approve leave, verify queue → Lambda log and DynamoDB deduplication, and upload a synthetic document to S3.

## Environment isolation and state

Production operations should store state in a **pre-provisioned S3 backend with S3 versioning/encryption and state locking enabled**. Bootstrap the backend separately and configure `backend "s3"` or `-backend-config` for each environment using unique state keys. Protect state permissions. The DB password appears in Terraform state even though the variable is marked `sensitive`; treat all state as secret material, use short-lived AWS credentials, and avoid storing passwords or tokens in Git.

You can initialize production with a **separate folder/state** using `environments/prod.tfvars.example` and unique VPC CIDR. For production, this example offers two ECS tasks, private ECS with a **single** NAT gateway, RDS Multi-AZ, longer log retention, and deletion protection. A **single NAT is not fully AZ-resilient**; for production availability use one NAT gateway per AZ or appropriate VPC endpoints, HTTPS internal service communication where required, restricted egress, AWS WAF/custom domain/ACM if exposed publicly, alarms, backup verification, autoscaling, and environment-specific budgets. Those are hardening tasks, not all implemented in this baseline.

## Known deployment boundaries

- The original source project's `handler.py` is packaged, not replaced with a dummy handler; successful duplicate-event handling requires DynamoDB.
- This project does **not** implement CodePipeline, automatic ECS blue/green rollout, SES email delivery, real-user provisioning, MySQL schema migrations as Terraform resources, or fully managed Terraform remote-state bootstrapping.
- RDS snapshots and existing data are *not* copied into the new environment. Higher environments start with empty databases unless you deliberately restore approved data.
- The initial ECS task definitions refer to ECR tags even when images have not yet been built. This is valid while `enable_services=false`; the services won't start until you turn it on.
- Docker image content, Spring config and Flyway migrations must be compatible with the environment variables; check logs/health after deploy.
- Avoid `terraform destroy` on production. It can delete critical resources and data, subject to protection and snapshot settings.
