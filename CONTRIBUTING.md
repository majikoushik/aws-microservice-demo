# Contributing / classroom exercises

1. Fork or clone; use Java 21 and Maven 3.9+.
2. Create a feature branch. Preserve compatibility with the `local` H2 profile so contributors do **not** need AWS credentials.
3. Add a Flyway migration whenever you change an entity schema. Do not modify old migrations used by already deployed databases.
4. Add one happy-path test, one authorization test and one edge-case test for new endpoints.
5. Run `mvn clean verify` and the Python notification unit test.
6. Do not commit employee data, passwords, AWS keys, ECR tokens, Terraform state, `.env` files or synthetic PDFs containing real names.
7. Clearly differentiate deployed features from architecture proposals in public README and resume descriptions.

Ideas: add proper leave policy/calendar, direct S3 upload via presigned POST, testcontainers-based MySQL tests, service-specific schema users, OpenTelemetry tracing, branch deployment preview, Redis caching with benchmarks, AWS Step Functions onboarding workflow.
