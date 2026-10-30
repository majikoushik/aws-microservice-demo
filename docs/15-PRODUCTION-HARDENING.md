# 15 — What to harden before production

**This is a portfolio/teaching project. Do not process real employee PII with this sample as-is.**

## Highest-priority improvements

1. **Real identity lifecycle:** Authorization Code + PKCE, MFA, JWT scope policy, refresh-token controls and token-revocation strategy, custom role mapping and policy tests, tenant isolation where relevant.
2. **Database boundaries:** separate schema and database credentials per service; dedicated secrets and least-privilege SQL; audited migrations, safe deployment sequence; avoid shared RDS master account.
3. **High availability:** Multi-AZ RDS, point-in-time backups, private subnets + VPC endpoints/NAT tradeoff, autoscaling, latency SLOs, alarms and incident response.
4. **Event outbox for scale:** atomic row claiming (`SELECT ... FOR UPDATE SKIP LOCKED`) or Debezium CDC, transient/persistent errors, ordering and dead-letter replay; avoid duplicate publishers across replicas.
5. **Idempotent HTTP APIs:** handle client retries with an idempotency key, DB uniqueness constraints for leave intervals, explicit optimistic locking conflict mapping and backoff.
6. **File security:** verify magic bytes, virus scanning/quarantine, object tagging, document retention/deletion policy, direct-to-S3 multipart uploads and upload/metadata compensation.
7. **Observability:** OpenTelemetry traces, structured JSON logs, X-Ray or OTel collector, dashboards for p95 latency, 4xx/5xx, SQS age, DLQ count, ECS restarts, DB load.
8. **Supply chain/CI/CD:** dependency CVE scans, container signing, SBOM, per-service build selection, protected branches, mandatory reviews, automated integration tests on real MySQL and AWS staging.
9. **Network/TLS:** encrypted service-to-service calls, RDS enforced TLS with CA verification (current `useSSL/requireSSL` is not a complete CA-verification setup), tightly scoped egress and no internet-addressable container IPs.
10. **Functional HR rules:** public holidays, leave accrual, working-day counting, time zones, manager reassignment, overlap/concurrency in leave issuance, update-history and retention requirements.

## Known educational compromises

- The simple outbox publisher does not claim rows across replicas; **keep Leave Service desired count 1** in the provided Terraform.
- Sample Lambda handler conditionally records dedup before logging; this is NOT exactly-once email delivery.
- H2 in-memory resets on process restart; AWS MySQL persists until Terraform destroy.
- AWS database is shared `workforce` schema for cost; no separate SQL credentials.
- API Gateway routes and backend validate JWT signatures; application-level `token_use=access` and `client_id` checks are implemented.
- No frontend/UI or actual email sending is built.
- `@Version` supports optimistic locking but no fully serialized overlap scheduling; don't make payroll/compliance promises.
