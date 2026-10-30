# 01 — Local run, no Docker and no external database

## Objectives

Run TWO independently started Spring Boot processes, create/read employee records, submit leave, approve leave, see the balance change, mark attendance, upload a PDF, and inspect the locally simulated SQS event.

## Prerequisites

- Java Development Kit 21 (`java -version`, `javac -version`)
- Maven 3.9+ (`mvn -version`), internet for the **first dependency download**
- IntelliJ IDEA Community or Ultimate (optional), terminal / PowerShell, Postman or curl
- Ports **8081** and **8082** free. No Docker, no MySQL, no AWS account.

## Windows 11 PowerShell — exact steps

1. Extract the ZIP and open PowerShell **in the repository root** (folder containing `pom.xml`).
2. Run `mvn -DskipTests install`. This installs the shared `common-web` module into local Maven cache and builds two runnable JARs.
3. Run `mvn -pl employee-service spring-boot:run "-Dspring-boot.run.profiles=local"`. Leave this terminal running.
4. Open **another** terminal in the same root and run `mvn -pl leave-service spring-boot:run "-Dspring-boot.run.profiles=local"`.
5. Visit `http://localhost:8081/actuator/health` and `http://localhost:8082/actuator/health`. Expect JSON containing `"status":"UP"`.

If using IntelliJ: **File → Open → select root `pom.xml` → Open as Project**. Import Maven modules and select JDK 21. Run `EmployeeApplication` with Active profiles=`local`; then separately run `LeaveApplication` with the same profile. Both mains are in `src/main/java/...`.

### Why `mvn install` once?

The parent is a Maven **multi-module** project. `common-web` is a library, not a standalone Spring Boot server. Running `spring-boot:run` from the individual module works after its dependency has been installed once. To build everything and run tests use `mvn clean verify` from the root.

## Local H2 and migrations

Each microservice has its own **in-memory H2 database** (`jdbc:h2:mem:employees` and `jdbc:h2:mem:leaves`). Flyway executes SQL migrations from the module's `src/main/resources/db/migration/` on startup; Hibernate validates mappings, it does not generate tables. All local data resets on process restart.

Employee service initializes three fake people on first startup with IDs 1–3. Leave balances are initially **20 calendar days**, created on the first approval; this is an educational rule, not a real HR policy.

## Role impersonation ONLY for local teaching

```powershell
# Read Alice as Alice, without a real login:
Invoke-RestMethod 'http://localhost:8081/api/employees/1' -Headers @{
  'X-Demo-Role' = 'EMPLOYEE'; 'X-Demo-Subject' = 'employee-alice'
}
# Manager sees team:
Invoke-RestMethod 'http://localhost:8081/api/employees' -Headers @{
  'X-Demo-Role' = 'MANAGER'; 'X-Demo-Subject' = 'manager-maria'
}
```

Local header roles are not cryptographically authenticated. Profile `aws` does **not** install the demo-header filter. Do not make port 8081 or 8082 internet-accessible while local auth is enabled.

## Create and approve leave (PowerShell)

```powershell
$alice = @{'X-Demo-Role'='EMPLOYEE'; 'X-Demo-Subject'='employee-alice'}
$manager = @{'X-Demo-Role'='MANAGER'; 'X-Demo-Subject'='manager-maria'}
$start = (Get-Date).AddDays(10).ToString('yyyy-MM-dd')
$end = (Get-Date).AddDays(12).ToString('yyyy-MM-dd')
$payload = @{employeeId=1;startDate=$start;endDate=$end} | ConvertTo-Json
$r = Invoke-RestMethod -Uri 'http://localhost:8082/api/leaves' -Method POST -Headers $alice -ContentType 'application/json' -Body $payload
$r | Format-List
Invoke-RestMethod -Uri "http://localhost:8082/api/leaves/$($r.id)/approve" -Method POST -Headers $manager -ContentType 'application/json' -Body '{}'
Invoke-RestMethod -Uri 'http://localhost:8082/api/leaves/employee/1/balance' -Headers $alice
```

Expected balance after a three-calendar-day approval: **17**. Try approving again: expect HTTP 409 (already decided). Check the leave-service console: a local event will be printed by the scheduled outbox worker.

## Attendance and documents

```powershell
$attendance = @{employeeId=1;date=(Get-Date).ToString('yyyy-MM-dd');status='PRESENT'} | ConvertTo-Json
Invoke-RestMethod -Uri 'http://localhost:8082/api/attendance' -Method POST -Headers $alice -ContentType 'application/json' -Body $attendance
```

Create a harmless `test.pdf` or select an existing synthetic PDF. For multipart file upload, use Postman form-data `file` or curl:

```bash
curl -X POST -H 'X-Demo-Role: EMPLOYEE' -H 'X-Demo-Subject: employee-alice' -F 'file=@test.pdf;type=application/pdf' http://localhost:8081/api/employees/1/documents
```

The response includes document ID; then `GET /api/employees/1/documents/{docId}/download` returns a local protected `/content` path. The file bytes are saved under `local-uploads/` (gitignored). S3 presigned downloads are only used in AWS.

## Run the tests

`mvn clean verify` (requires Maven Central dependencies on the first run); see [12 — Tests](12-TESTS-AND-TROUBLESHOOTING.md).
