# 08 — Full AWS deployment: from clean account to live API

> **Read first:** Deploying this tutorial **creates billable resources**. Confirm your AWS plan, available credit, region and [cost guide](11-COST-AND-CLEANUP.md). This is a repeatable reference deployment, not an assertion it has been provisioned against your account.

## Overall phases

A. Prepare permissions and tools → B. Create ECR repos → C. Build/push two images → D. Terraform `apply` all infrastructure → E. Configure Cognito sample users → F. Exercise API, SQS and CloudWatch → G. Destroy resources.

The initial two-phase provisioning solves a bootstrap problem: ECS cannot pull its container images until ECR has the initial images. Terraform targets are used *only for the first ECR bootstrap*. Subsequent deployments should use CI/CD and normal plans.

## A — Prerequisites

1. A valid AWS account eligible to create ECS/Fargate, RDS, API Gateway, Cognito, ECR and Lambda. **New Free plan account restrictions or credits can vary.**
2. AWS CLI v2, Terraform >=1.6, Docker Engine/Desktop and `jq` on Bash-based deployment machines. Local Spring Boot app itself does NOT need Docker.
3. Sufficient AWS IAM permissions for the services above, with `sts:GetCallerIdentity`, `iam:PassRole`, `codeconnections:*` if enabling pipeline. AdministratorAccess can bootstrap an isolated disposable learning account but must not be used as a long-term production strategy.
4. Select one region; examples use **Mumbai `ap-south-1`**, subject to quotas and service availability.
5. Configure credentials **outside the repo**: `aws configure` or `aws configure sso` (recommended for human identities), then `aws sts get-caller-identity`.
6. Use synthetic employee accounts only. Never upload personal HR data.

## B — Edit variables, set cost alert, initialize Terraform

```bash
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
# Edit terraform.tfvars: budget_email, aws_region, unique project_name
terraform -chdir=infrastructure/terraform init
terraform -chdir=infrastructure/terraform fmt -recursive
terraform -chdir=infrastructure/terraform validate
terraform -chdir=infrastructure/terraform plan
```

On Windows PowerShell:

```powershell
Copy-Item infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
notepad infrastructure/terraform/terraform.tfvars
terraform -chdir=infrastructure/terraform init
terraform -chdir=infrastructure/terraform fmt -recursive
terraform -chdir=infrastructure/terraform validate
terraform -chdir=infrastructure/terraform plan
```

**Terraform may include generated RDS secrets in state; keep the state encrypted, private and outside Git.** This example uses local state to minimize teaching setup. For team usage, create a secure remote S3 state backend with encryption and locking before applying.

## C — Bootstrap ECR first

```bash
terraform -chdir=infrastructure/terraform apply \
 -target=aws_ecr_repository.employee \
 -target=aws_ecr_repository.leave
```

Using Terraform `-target` routinely is discouraged; here it is solely to create repositories required by the initial images.

Get the repositories:

```bash
terraform -chdir=infrastructure/terraform output -raw ecr_employee
terraform -chdir=infrastructure/terraform output -raw ecr_leave
```

If your target apply does not yet expose outputs, read repository URLs from the ECR console or use `aws ecr describe-repositories --repository-names workforce-demo/employee workforce-demo/leave`.

## D — Build and push application containers

Docker is needed *now*, for the cloud runtime, NOT for local development.

Bash/macOS/Linux:

```bash
./scripts/deploy-images.sh v1
```

Windows PowerShell manual equivalent:

```powershell
$region = 'ap-south-1'   # match terraform.tfvars
$account = aws sts get-caller-identity --query Account --output text
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "$account.dkr.ecr.$region.amazonaws.com"
$employeeRepo = "$account.dkr.ecr.$region.amazonaws.com/workforce-demo/employee"
$leaveRepo = "$account.dkr.ecr.$region.amazonaws.com/workforce-demo/leave"
docker build -f employee-service/Dockerfile -t "${employeeRepo}:v1" .
docker build -f leave-service/Dockerfile -t "${leaveRepo}:v1" .
docker push "${employeeRepo}:v1"
docker push "${leaveRepo}:v1"
```

If you customized `project_name`, change the ECR repository names accordingly. Docker builds run Maven in a multi-stage build and produce minimal Java 21 JRE images with a non-root user.

## E — Apply full Terraform

```bash
terraform -chdir=infrastructure/terraform plan
terraform -chdir=infrastructure/terraform apply
terraform -chdir=infrastructure/terraform output
```

Core resources include: VPC/subnets/SG, private RDS MySQL, Cognito pool/groups/client, Secrets Manager, S3, ECR, ECS/Fargate, Cloud Map, API Gateway VPC Link and JWT authorizer, SQS+DLQ, Lambda+DynamoDB, CloudWatch log groups and AWS Budgets.

**Expect provisioning to take time.** RDS and VPC Link readiness are asynchronous. Check ECS service events and tasks in the console rather than assuming Terraform `apply` implies container health.

## F — Inspect services (CLI)

```bash
terraform -chdir=infrastructure/terraform output -raw api_base_url
aws ecs list-clusters --region ap-south-1
aws ecs describe-services --cluster workforce-demo-cluster \
 --services workforce-demo-employee workforce-demo-leave --region ap-south-1
aws logs describe-log-groups --log-group-name-prefix /ecs/workforce-demo --region ap-south-1
```

The API Gateway routes are JWT-protected; `curl API_BASE/api/employees` without an `Authorization: Bearer ACCESS_TOKEN` should return 401. ECS health checks contact `/actuator/health` internally and do not require public health routes.

**Troubleshoot 503**: check Cloud Map instances for healthy tasks, ECS task events, CPU/memory, image pull, DB access, and VPC Link `AVAILABLE` state. **Troubleshoot JDBC errors**: ensure Secrets Manager read permission, RDS endpoint, MySQL 3306 SG rule, Flyway SQL, and that master database `workforce` exists.

## G — Create Cognito identities and test JWTs

Follow [09 — Cognito](09-COGNITO-AND-TESTING.md). The local seeded `employee-alice` etc do **not** exist in MySQL AWS; create AWS Employee records with Cognito `sub` values, then request leave with actual generated DB IDs.

## H — Observe SQS, Lambda and DynamoDB

Approve a leave with a valid manager JWT. The Leave Service inserts an outbox row. The scheduled publisher sends its JSON to SQS. The Lambda event source mapping invokes Python `handler.lambda_handler`, conditionally writes eventId to DynamoDB and logs synthetic event IDs and leave IDs. Inspect CloudWatch Logs for `/aws/lambda/workforce-demo-notification` and the DynamoDB table.

## I — Optional pipeline

Once the manual deployment succeeds, read [10 — CI/CD](10-CICD.md) for CodeConnections GitHub authorization and enable the CodePipeline module.

## J — Destroy to stop spending

`terraform -chdir=infrastructure/terraform destroy` from the **same initialized state directory**. Verify that RDS, ECS, S3, NAT/IP, Secrets Manager, CloudWatch, ECR and VPC links are gone, and check Cost Explorer afterward. **Terraform state must be saved securely until cleanup completes.**

## Architectural caveats

- Shared RDS `workforce` schema rather than physical service DB separation (for cost); separate Flyway tables are owned by each service.
- Public IPv4 **outbound** app tasks, strict inbound SG rules; no NAT/ALB. Cost-aware, not production default.
- DynamoDB dedup Lambda only logs, no SES sender; no actual emails.
- Persistent 24/7 RDS and ECS incur costs; destroy when finished rather than relying on sleep/scale-to-zero assumptions.
- Verify AWS feature support, service quotas and exact prices on your own account/region before `apply`.
