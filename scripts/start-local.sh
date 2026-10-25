#!/usr/bin/env bash
set -euo pipefail
# Run in TWO terminals (or use IntelliJ twice). No Docker/MySQL/AWS account.
cd "$(dirname "$0")/.."
if [[ "${1:-}" == "employee" ]]; then
  mvn -q -DskipTests install
  exec mvn -pl employee-service spring-boot:run -Dspring-boot.run.profiles=local
elif [[ "${1:-}" == "leave" ]]; then
  # -am may invoke spring-boot:run on the non-executable common-web module.
  # Install both library and service JARs once, then run the selected module.
  mvn -q -DskipTests install
  exec mvn -pl leave-service spring-boot:run -Dspring-boot.run.profiles=local
else
  echo 'Usage: ./scripts/start-local.sh employee|leave'
  exit 2
fi
