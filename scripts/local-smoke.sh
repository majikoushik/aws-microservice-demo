#!/usr/bin/env bash
set -euo pipefail
# Start employee-service 8081 and leave-service 8082 first.
EMPLOYEE="http://localhost:8081"
LEAVE="http://localhost:8082"
echo 'Health: '
curl -fsS "$EMPLOYEE/actuator/health";echo
curl -fsS "$LEAVE/actuator/health";echo
printf '\nAlice can see herself:\n'
curl -fsS -H 'X-Demo-Role: EMPLOYEE' -H 'X-Demo-Subject: employee-alice' "$EMPLOYEE/api/employees/1";echo
printf '\nHR lists employees:\n'
curl -fsS -H 'X-Demo-Role: HR' -H 'X-Demo-Subject: hr-helen' "$EMPLOYEE/api/employees?page=0&size=3";echo
