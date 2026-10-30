# 16 — Build, verification and environment limitations

## Source and runtime validation

This ZIP contains source files, not compiled dependencies, pre-configured AWS access or an AWS deployment. After extraction, perform verification in a machine with Maven 3.9+ and internet access to Maven Central:

```bash
mvn -version
mvn clean verify
python -m unittest discover -s notification-lambda -p 'test_*.py' -v
terraform -chdir=infrastructure/terraform init
terraform -chdir=infrastructure/terraform fmt -recursive
terraform -chdir=infrastructure/terraform fmt -check -recursive
terraform -chdir=infrastructure/terraform validate
```

Then run the two local services and execute the smoke API requests. On AWS, begin with a plan, ECR bootstrap, actual `apply` and service/CloudWatch checks as described in chapter 08.

## What is not possible to prove from just generating a ZIP?

- That every external Maven dependency resolves in *your* environment.
- That Terraform can create the intended resources in *your* specific account/region/quotas.
- That Fargate services become healthy before runtime IAM, RDS migrations, Cognito identities and images are configured.
- That future AWS pricing, Free Tier allowances and GitHub OAuth handshake will remain unchanged.

The included code is a **reference learning implementation**, not proof of a deployment. Update this file with the results of your own test runs and cloud verification before advertising completion publicly.

## Suggested evidence to add after you run it

- Screenshot: two Spring Boot services running locally on ports 8081 and 8082.
- Maven output: all tests passed.
- Postman: owner authorized, cross-employee 403, approval and balance 17.
- ECS: healthy service tasks and distinct task definitions.
- API Gateway: successful JWT-authenticated request.
- CloudWatch: request ID across services and Lambda event.
- CodePipeline: green Build and Deploy stages.
- AWS Budgets: alerts configured and teardown complete.
