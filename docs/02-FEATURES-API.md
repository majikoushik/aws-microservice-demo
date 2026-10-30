# 02 — Implemented features and REST API contract

## Service ownership

**Employee Service** (8081) owns employee profiles, manager/department metadata, document metadata and file storage integration. **Leave Service** (8082) owns attendance, leave requests, leave balances, approval audit records and outbound events. The latter queries Employee Service **through REST**, not via SQL joins.

## Employee Service endpoints

| Method | URL | Role | Notes |
|---|---|---|---|
| GET | `/api/employees/{id}` | Owner, their manager, HR | Returns identitySubject, name, email, department, managerSubject |
| GET | `/api/employees?page=0&size=10&department=Engineering` | HR or manager | HR can filter by department; managers see only their team |
| POST | `/api/employees` | HR | Create employee (subject must match Cognito subject on AWS) |
| PUT | `/api/employees/{id}` | HR | Update profile and manager assignment |
| POST | `/api/employees/{id}/documents` | Owner, manager, HR | Multipart `file` PDF/JPEG/PNG, <=5 MB |
| GET | `/api/employees/{id}/documents` | Owner, manager, HR | List metadata |
| GET | `/api/employees/{id}/documents/{docId}/download` | Owner, manager, HR | Local protected path or 5-min S3 URL |
| GET | `/api/employees/{id}/documents/{docId}/content` | Authorized local users only | Stream local file content; 404 on AWS |

### Employee POST example

```json
{
  "identitySubject": "user-sub-from-cognito-or-local-demo",
  "name": "Test Employee",
  "email": "employee@example.test",
  "department": "Engineering",
  "managerSubject": "manager-sub-from-cognito"
}
```

## Attendance/Leave Service endpoints

| Method | URL | Role | Notes |
|---|---|---|---|
| POST | `/api/attendance` | Owner, HR | One record per employee and calendar date, no future dates |
| GET | `/api/attendance/employee/{id}` | Owner, manager, HR | List attendance |
| POST | `/api/leaves` | Owner, HR | Date validity, overlap checks; at most 30 calendar days |
| GET | `/api/leaves/employee/{id}` | Owner, manager, HR | List leave requests |
| GET | `/api/leaves/employee/{id}/balance` | Owner, manager, HR | 20 days default, decremented on approvals |
| POST | `/api/leaves/{id}/approve` | Assigned manager or HR | Decrement balance, audit and enqueue event atomically |
| POST | `/api/leaves/{id}/reject` | Assigned manager or HR | Record rejection and audit |
| GET | `/api/leaves/{id}/audit` | Owner, assigned manager, HR | Ordered audit entries |

### Attendance example

```json
{"employeeId":1,"date":"2026-10-24","status":"PRESENT"}
```

Accepted statuses: `PRESENT`, `REMOTE`, `ABSENT`.

### Leave request example

```json
{"employeeId":1,"startDate":"2026-12-01","endDate":"2026-12-03"}
```

### Approval example

```json
{"comment":"Team delivery covered, approved."}
```

### Common response patterns

- 200: GET/successful decision; 201: new employee/attendance/leave/document record
- 400: request validation / bad date / bad file
- 401: no valid authentication
- 403: authenticated, but not permitted to access the particular record
- 404: missing resource
- 409: duplicate request, duplicate email, duplicate attendance, insufficient balance or repeated approval
- 502: employee service unreachable from leave service

**Caveats:** There is no frontend UI; API clients are Postman, curl, or PowerShell. No actual email is sent, and the demo intentionally counts calendar days (not working days). The employee service exposes a manager's `managerSubject` and identity identifiers to authorized users; further minimization is appropriate for production.
