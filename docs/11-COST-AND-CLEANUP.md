# 11 — AWS Free Tier, $100 credit budget and cleanup

## Important distinction: Free Tier vs promotional credits

An AWS service may **support Free Tier account access** but still incur metered usage. New AWS Free plan rules (since July 2025) and historical account allowances vary. Promotional credits have expiry dates, eligibility rules and excluded services. Verify your account's **Billing → Credits** and current AWS Free Tier page before deployment. This repo deliberately does **not** assert all services are free.

## Primary recurring costs

1. **RDS MySQL:** charged for allocated/active database instance plus storage (instance can be billable continuously). Single AZ, one 20 GiB volume, no read replica, backup retention 0 for disposable demo.
2. **Fargate:** two tasks allocated 0.5 vCPU and 1 GiB each, when running, even with no HTTP requests. Each task receives a billable public IPv4.
3. **API Gateway / SQS / Lambda / DynamoDB:** typically small for low-volume class demonstrations but subject to requests and duration.
4. **S3 / ECR / CloudWatch / Secrets Manager:** low usage still may produce storage and/or fixed secret charges.
5. **CodeBuild/CodePipeline:** builds and pipelines can incur usage charges if enabled or triggered frequently.

The Terraform template has **no NAT Gateway, Application Load Balancer, managed Redis, EKS cluster or Multi-AZ RDS**. These choices reduce recurring costs but are not general production recommendations.

## Estimate first

Use https://calculator.aws/ and https://aws.amazon.com/free/ for your region and your actual account plan. The $100 credit is a **spending budget**, not a duration guarantee. A 24/7 running RDS instance and two Fargate tasks can consume credits significantly faster than a demo deployed for occasional short sessions.

## Up-front checklist

- Check AWS plan type and promotional credit expiration.
- Use `budget_email` in Terraform (Budget 60% and 90% warning thresholds).
- Optionally configure an account-level AWS Free Tier usage alert and a billing alarm.
- Set project-specific tags (included).
- Do not upload real employee data, images or scanned documents.
- Never use `terraform apply` unattended with unfamiliar changes.
- Never commit `.tfstate`, credentials or `terraform.tfvars` to GitHub.

## Cost-aware run schedule

Develop the complete project locally using **free local H2** and file storage. For a workshop, deploy AWS resources in advance, conduct the demo, take screenshots of architecture/deployments/metrics, then **destroy the AWS deployment**. Stopping ECS tasks alone is insufficient to stop RDS and other storage charges. Reducing desired count to zero stops task compute charges but does not eliminate all recurring costs.

## Teardown — essential

```bash
terraform -chdir=infrastructure/terraform destroy
```

Confirm a clean state using the console: ECS services and tasks, RDS DB instances, VPC Links, ECR, S3, Secrets Manager, CloudWatch log groups, SQS/DLQ, DynamoDB, Lambda, CodePipeline/CodeBuild, VPC networking and any public IPv4 allocations. Some resources, budgets and logs can retain small costs/entries after application teardown; check Billing again after cost data posts.

**Never rely on an alert to halt spending.** A budget notification does not automatically stop workloads. Paid-plan billing can continue after credits expire. Free-plan resources can be suspended when time/credits are exhausted; the details depend on account eligibility and plan.

## Official pricing references (check current rates, region and exclusions)

- https://aws.amazon.com/ecs/pricing/
- https://aws.amazon.com/fargate/pricing/
- https://aws.amazon.com/rds/mysql/pricing/
- https://aws.amazon.com/vpc/pricing/
- https://aws.amazon.com/s3/pricing/
- https://aws.amazon.com/apigateway/pricing/
- https://aws.amazon.com/codepipeline/pricing/
- https://aws.amazon.com/codebuild/pricing/
