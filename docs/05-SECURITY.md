# 05 — Security: local demo headers vs AWS real tokens

## Local profile: intentionally insecure by design

Under `spring.profiles.active=local`, only the explicit pair `X-Demo-Role` + `X-Demo-Subject` authenticates. There is no password, signature or token verification. Its sole purpose is to teach object-level authorization before setting up Cognito. **Do not expose local endpoints to the network or use this profile in AWS.** All routes other than `/actuator/health` require a demo identity.

## AWS profile

1. Cognito user pool issues signed JWT access tokens; Cognito groups contain `EMPLOYEE`, `MANAGER`, `HR`.
2. API Gateway HTTP JWT authorizer checks token issuer and client audience, rejecting missing/invalid tokens.
3. Spring Security's OAuth2 Resource Server **revalidates** JWT signatures and issuer. A converter maps `cognito:groups` into `ROLE_EMPLOYEE`, etc.
4. Business methods compare `Authentication.getName()` (Cognito JWT `sub`) with `identitySubject` stored in Employee Service and compare manager `sub` to `managerSubject`.
5. Leave Service forwards the original bearer token to Employee Service during its REST lookup; that service enforces team/owner access again.

**Note:** The code relies on Cognito access-token signatures, issuer and API Gateway audience checks. For defense in depth, the Spring service additionally checks access-token `token_use` and `client_id` and turn on TLS/mTLS on internal services in production.

## IAM vs Cognito vs Spring Security

- **Cognito / Spring Security** answers: *Which employee/manager/HR can access this record?*
- **IAM Task Role** answers: *May this employee service write documents to this S3 prefix? May leave service send to SQS?*
- **ECS Execution Role** answers: *May ECS pull an ECR image, write logs, fetch Secrets Manager?*
- **Security Groups** answer: *Which network sources can connect to app and database ports?*

Never send AWS keys from Postman. ECS obtains short-lived role credentials automatically.

## Upload security

Private S3 bucket with Block Public Access and default encryption; randomized keys; content-type/size allowlist; request authorization **before** file access; 5-minute presigned download URL. Production upgrades: inspect actual file signatures rather than trusting `Content-Type`, malware scanning, log sanitization, content disposition controls, quotas, multipart direct-to-S3 uploads, and upload/metadata compensation on DB failures.

## Secrets

AWS Secrets Manager stores RDS password, injected as ECS task secret. RDS credentials are also present in Terraform state because Terraform provisions them — **never commit `.tfstate` or `terraform.tfvars`**. Prefer an encrypted remote backend for a multi-user project. AWS uses a shared master DB user in this low-cost demo: production should use service-specific credentials.

## Threat modeling practice

Try an EMPLOYEE token / demo identity for `/api/employees/2`: it must give 403; try a manager from a different team; try unauthenticated endpoints; try a duplicate employee email. Do not place real PII in CloudWatch log messages, SQS payloads, sample dumps, or screenshots.
