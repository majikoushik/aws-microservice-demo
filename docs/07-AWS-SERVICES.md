# 07 — AWS service-by-service learning map

| Service | How this repository uses it | Skills to demonstrate |
|---|---|---|
| IAM | ECS execution/task roles, Lambda role, CodeBuild/CodePipeline roles | Least privilege, trust policies, identity vs resource permissions |
| VPC/Subnets/SG | Two AZs, public app subnets, private RDS, SG-to-SG rules | Routing, egress, task isolation, security boundaries |
| ECS/Fargate | Two independently deployable Spring Boot containers | Task definitions, desired count, health checks, redeployments |
| ECR | Versioned `employee`, `leave` OCI images | Docker build, vulnerability scan, tag and lifecycle |
| API Gateway HTTP API | JWT-protected HTTP paths | Routes, stages, JWT authorizer, HTTP_PROXY |
| VPC Link / Cloud Map | ECS service endpoints without an ALB | Private integrations, SRV discovery, A record internal REST |
| Cognito | User pool/groups/token issuance | Authn vs authz, signed JWTs, identity subject |
| RDS MySQL | One cost-conscious instance, separate owned tables | Managed DB, Flyway, storage, backups and limitations |
| S3 | Private document files | Bucket policy, task role, presigned URLs, object lifecycle |
| Secrets Manager | ECS-injected MySQL password | Secret delivery, avoid plaintext in source |
| SQS | Async notification queue and DLQ | At-least-once semantics, visibility timeout, redrive |
| Lambda | Poll SQS only when events exist | Event source mapping, partial batch failures |
| DynamoDB | Conditional event dedup + TTL | Idempotency, pay-per-request billing |
| CloudWatch | ECS log groups, Lambda logs, basic metrics | Correlate requests, troubleshoot deployments |
| CodeBuild | Maven tests, image builds and ECR push | Buildspec, privileged Docker builds, IAM |
| CodePipeline | Optional GitHub source + Build + two ECS deploy actions | Change-driven deployment stages, artifact passing |
| AWS Budgets | Monthly warning notifications | Cost visibility and teardown culture |

## Why not ALB or NAT Gateway at first?

ALB has an hourly base charge even when idle. NAT Gateway has hourly and data processing costs. The AWS HTTP API + Cloud Map route is an alternative explicitly supported by AWS. ECS app tasks get public IP addresses solely for **outbound** API/ECR connectivity, while ingress is restricted to the API Gateway VPC Link SG and internal ECS SG. This has trade-offs and is not a universal production pattern.

## Why no EC2 host?

Fargate eliminates host OS maintenance and makes tasks an independently deployable unit. An EC2 small instance could be cheaper for long idle periods, but would teach a different operations model. ECS-on-EC2 and EKS are useful second projects, not necessary for this one.

## AWS official references

- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html
- https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-private.html
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html
- https://docs.aws.amazon.com/AmazonSQS/latest/dg/welcome.html
- https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html
- https://aws.amazon.com/free/
- https://calculator.aws/
