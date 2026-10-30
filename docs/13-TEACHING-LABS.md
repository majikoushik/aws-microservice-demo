# 13 — Teaching syllabus: 12 guided labs

Each lab builds on the previous one. Suggested format: 15 minutes concept, 20 minutes code walkthrough, 20 minutes student exercise, 5 minutes interview question.

| Lab | Topic | Live demonstration | Assignment |
|---|---|---|---|
| 1 | Spring Boot REST | Run Employee Service, GET 1 | Add GET by email |
| 2 | JPA + H2 | Show seed data, Flyway migration | Add search by name |
| 3 | Layered architecture | Trace Controller→Service→Repository | Add employee validation |
| 4 | Security and RBAC | Alice cannot read Bob | Add department-admin role |
| 5 | Microservices | Run 2 ports, trace HTTP request | Stop upstream and observe failure |
| 6 | Reliability | Circuit breaker and timeout | Sketch retry safety policy |
| 7 | Concurrency/SQL | Approve once, retry 409 | Explain @Version and lost update |
| 8 | Event-driven architecture | Outbox poller logs JSON | Simulate SQS duplicate delivery |
| 9 | File/object storage | Upload local PDF | Draw S3 pre-signed URL flow |
| 10 | Containers/AWS ECS | Docker build and ECR push | Compare ECS vs EC2 vs Lambda |
| 11 | VPC/IAM/API Gateway | Inspect Terraform architecture | Explain SG and Cognito roles |
| 12 | CI/CD/Operations | Buildspec, CodePipeline, CloudWatch | Simulate bad release + cleanup |

## Demo checkpoints

- Lab 1: `http://localhost:8081/actuator/health` responds.
- Lab 4: GET employee 2 as Alice returns 403.
- Lab 5: Leave Service depends on Employee Service but not its tables.
- Lab 7: Initial balance 20 becomes 17 after a 3-day approval, remains 17 after duplicate approval is rejected.
- Lab 8: Leave console contains an eventId and status log.
- Lab 9: file metadata remains separate from bytes.
- Lab 11: compare IAM task role vs Cognito roles and private vs public subnet.
- Lab 12: use Terraform destroy to demonstrate cost control.

## Concept questions

1. Why does splitting code into multiple packages NOT automatically create microservices?
2. Why should the Leave Service not join Employee Service's SQL tables?
3. Why is it dangerous to blindly retry a POST approval?
4. Can `@Transactional` include an AWS SQS send in the same atomic transaction?
5. What is the difference between authentication and authorization?
6. What does DynamoDB's conditional write guarantee, and what does it NOT guarantee for an email sender?
7. Why might a container be healthy locally but fail in AWS?
8. What are the AWS costs of leaving a small demo running overnight?

## Grading rubric

Award marks for: working local API (20%), ownership/security rules (15%), data model/migrations (15%), microservice communication (15%), event/transaction correctness (15%), tests (10%), deployment documentation and cost awareness (10%). For an advanced group, require two independent AWS ECS deployments and proof of CloudWatch observations.
