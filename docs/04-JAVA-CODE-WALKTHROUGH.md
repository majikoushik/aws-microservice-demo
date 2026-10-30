# 04 — Walk through the Java source in learning order

## Maven parent and shared library

The root `pom.xml` defines Java 21, Spring Boot parent dependency management and three modules. `common-web` contains shared web concerns only; **business models are not shared**. Why? Sharing a `Employee` JPA entity between services would recreate unwanted schema coupling.

`common-web/SecurityConfiguration.java` uses Spring profiles: local-only demonstration header authentication; AWS OAuth2 Resource Server JWT validation. `Identity.java` makes authorization checks readable. `ApiExceptionHandler.java` translates known failures into structured JSON. `RequestIdFilter.java` adds `X-Request-ID` to responses and MDC, so a series of log statements can be correlated.

## Employee Service

- `EmployeeApplication` — process entrypoint and configuration imports.
- `Employee.java` — one JPA entity; `@Version` supports concurrent-update detection.
- `EmployeeRepository.java` — Spring Data derived queries and paging.
- `EmployeeService.java` — service-layer authorization, validation and orchestration.
- `EmployeeController.java` — HTTP endpoints and DTO/request mapping. Controllers are deliberately thin.
- `DocumentController.java` — file validation, generated file keys, private file access, metadata persistence.
- `FileStore.java` + `LocalFileStore.java` / `S3FileStore.java` — **Strategy pattern** selected by `@Profile`. Compare `save` and `signedDownload` contracts.
- `LocalSeedData.java` — seeded sample identities for local demonstrations.

### Example: why a service method checks security

```java
Employee e = getEntity(id);
Identity.require(Identity.hasRole("HR") ||
    e.identitySubject.equals(Identity.subject()) ||
    (Identity.hasRole("MANAGER") && Identity.subject().equals(e.managerSubject)));
```

A user can guess any `/api/employees/{id}` number; the service must enforce record-level authorization, not just `@PreAuthorize("isAuthenticated()")`.

## Leave and Attendance Service

- `LeaveRequest.java` — state machine PENDING → APPROVED/REJECTED, plus `@Version`.
- `LeaveBalance.java` — mutable leave balance with optimistic locking.
- `LeaveAudit.java` — append-only history of decisions.
- `LeaveService.java` — domain rules and `@Transactional` decisions.
- `EmployeeDirectoryClient.java` — REST client with timeouts, token forwarding and Resilience4j `@CircuitBreaker`.
- `OutboxEvent.java` + `OutboxDelivery.java` — persistence and scheduled message transport; note retry and ordering tradeoffs.
- `AttendanceController.java` — request validation, duplicate date constraints, and authorization.

### Follow an approval from input to DB

`LeaveController.approve()` → `LeaveService.decide()` → `EmployeeDirectoryClient.lookup()` → authorization → `LeaveBalance` decrement + leave status update → audit creation → outbox event insertion → DB commit → `OutboxPublisher` sends to SQS or local logger.

## Flyway vs Hibernate DDL

Each service has `/db/migration/V1__...sql`; attendance has `V2`. `ddl-auto: validate` prevents Hibernate from quietly creating tables. For schema changes, write a new migration rather than editing an applied V1 migration. H2 runs in MySQL compatibility mode to reduce divergence but cannot perfectly emulate MySQL locking, indexes, collation and transaction behavior.

## JUnit test cases

The tests use H2 + MockMvc. Employee API test verifies unauthenticated=401, self=200, other employee=403, manager unable to create and HR able to create. Leave API test mocks only the upstream Employee Service, uses real local JPA and proves a duplicate approval is rejected while balance is decremented once.

**Exercise:** implement `PUT /api/attendance/{id}` with an audit row and demonstrate optimistic locking.
