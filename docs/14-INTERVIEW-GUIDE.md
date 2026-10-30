# 14 — Senior Java developer and AWS system-design interview guide

## Tell the architecture story (90 seconds)

"I built an Employee and Attendance/Leave application as two independently deployed Spring Boot services. Each service owns its business tables and database migrations. An AWS API Gateway HTTP API with Cognito JWT authorization forwards traffic through VPC Link and Cloud Map to two ECS Fargate services. The Leave Service does an authorized REST lookup on Employee Service. Leave approvals update balance, status, audit and an outbox record in one MySQL transaction; a publisher sends events to SQS, which triggers a Lambda worker. Employee documents use private S3 objects and pre-signed download URLs. Terraform provisions infrastructure; CodeBuild/CodePipeline automate test, build and ECS deployment." Only make this a past-tense claim after you have **actually deployed** the AWS version.

## Key discussions

**Why ECS + Fargate?** No host management, task-level IAM, simple independently deployable containers. **Why not EKS?** Kubernetes is unnecessary complexity at this scope.

**Why API Gateway + Cognito?** Edge routing and JWT validation. Services revalidate signatures and enforce record-level authorization; API Gateway is not a replacement for service authorization.

**Why Cloud Map?** Service discovery plus API Gateway private integrations, avoiding an always-running ALB. Cloud Map uses SRV records for API Gateway and A records for internal REST lookups.

**Why H2 locally and MySQL on AWS?** Fast onboarding and tests. H2 does not exactly emulate MySQL, so production requires MySQL-specific integration tests and migration verification.

**What if Employee Service fails?** Leave creation/approval lookup fails fast. Request times out and circuit breaker limits repeated calls. For critical workflows use domain-owned identity snapshots/events, well-defined stale-data policy, fallbacks where safe, and load testing.

**How do you prevent repeated leave deduction?** Enforce pending status, `@Transactional`, optimistic locking with `@Version`, appropriate HTTP conflict mapping and database constraints. For distributed API retries use idempotency keys in a hardened design.

**Why outbox instead of directly calling SQS?** Avoid DB success without event or event without DB success; publish asynchronously with at-least-once delivery, then deduplicate downstream.

**Why Lambda after SQS?** Notification processing is event-driven, so we avoid continuously running a third container; SQS buffers spikes and supports DLQ.

**What compromises are not production quality?** Shared RDS schema/master DB user, no automated scaling, public IPv4 tasks for egress, JWT group permissions still require application-policy review, one-instance outbox polling, no full file scanning, no actual SES integration, simplified annual leave rules.

## Senior-level improvement questions

- How would you introduce a database-per-service pattern with separate permissions?
- How would you deploy to private subnets without NAT Gateway, using VPC interface/gateway endpoints?
- How would you migrate RDS with no downtime and roll back incompatible schema changes?
- How would you tune connection pools for Fargate scaling to 30 tasks?
- How would you add a canary deployment and roll back using p95 latency/error-rate alarms?
- How would you enforce an application-level idempotency key for POST approvals?
- How would you implement JWT `token_use` and `client_id` validation in each backend?
- How would you export OpenTelemetry traces to AWS X-Ray and instrument RestClient?

## Resume description AFTER implementation

"Developed a Java 21/Spring Boot workforce-management portfolio using independently deployed ECS/Fargate microservices, Cognito-secured REST APIs, private API Gateway/Cloud Map routing, H2/MySQL with Flyway, S3 document management, transactional-outbox events via SQS/Lambda, CloudWatch observability, and Terraform-managed AWS CI/CD infrastructure." If the AWS deployment has not been completed, say **designed and prototyped** rather than **deployed**.
