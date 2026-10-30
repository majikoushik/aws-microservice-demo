# 12 — Testing strategy and troubleshooting

## Java test commands

```bash
mvn clean verify
mvn -pl employee-service -am test
mvn -pl leave-service -am test
```

Tests require downloaded dependencies from Maven Central on the first run. Java 21 recommended. `@ActiveProfiles("local")` forces H2/local security; Spring MockMvc exercises HTTP handlers without opening a real TCP port. The leave test mocks the **remote Employee Service client**, not JPA repositories, to validate actual database behavior.

## Python notification consumer

```bash
python -m unittest discover -s notification-lambda -p 'test_*.py' -v
```

This test uses an in-memory fake DynamoDB table. No boto3, AWS credentials or network needed. When running on Lambda, `boto3` is imported from the managed runtime.

## End-to-end manual test matrix

| Scenario | Who | Expected |
|---|---|---|
| GET employee 1 | No identity | 401 |
| GET employee 1 | Alice | 200 |
| GET employee 2 | Alice | 403 |
| POST employee | Manager | 403 |
| POST employee | HR | 201 |
| POST attendance same day twice | Alice | 201, then 409 |
| Request future leave | Alice | 201 PENDING |
| Approve Alice leave | Maria | 200 APPROVED |
| Approve again | Maria | 409 |
| Read leave balance | Alice | 20 - approved days |
| Upload PDF >5 MB | Alice | 400 or 413 depending on multipart size limit |
| Employee Service stopped, Leave Service calls it | Alice | Upstream failure (usually 502 or circuit breaker error) |

## Build errors

**`mvn` not found:** Install Apache Maven and add Maven `bin` to PATH. `java -version` must be 21. **`Could not resolve dependency`:** ensure access to Maven Central/enterprise proxy; this package intentionally contains source rather than bundled binary Maven dependencies. **`Port 8081 already in use`:** close another process or set a different `SERVER_PORT` and update `EMPLOYEE_SERVICE_URL` for the Leave Service.

**Flyway migrations fail:** Check H2 startup log, SQL under `db/migration`, and that `spring.jpa.hibernate.ddl-auto=validate`; do not delete applied production migration versions.

**403 during local call:** Both `X-Demo-Role` and `X-Demo-Subject` are necessary; a manager's `subject` must match employee's `managerSubject`. **Unexpected 502 from Leave Service:** Start Employee Service first; the client calls `http://localhost:8081` by default. Look for `X-Request-ID` in logs.

**AWS 401 vs 403:** 401 usually invalid/expired/missing JWT; 403 usually valid token without required group/object ownership. **AWS 503 from API Gateway:** check ECS healthy tasks, VPC Link availability and Cloud Map instances. **SQS event not published:** check `outbox_events` and leave logs; validate task IAM `sqs:SendMessage`. **S3 upload denied:** verify task role is attached to Employee task definition and object key begins with `employees/`.

## Scope of validation

Source-level/static sanity checks can run without network access. Java integration tests require local Maven dependency resolution, and AWS execution requires a real AWS account. See [validation notes](16-VALIDATION-NOTES.md) for what was or was not executed when this ZIP was assembled.
