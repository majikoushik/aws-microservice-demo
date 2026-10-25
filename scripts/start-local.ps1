param([Parameter(Mandatory=$true)][ValidateSet('employee','leave')][string]$Service)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
# Build shared module first. No Docker, local MySQL, or AWS account.
mvn -q -DskipTests install
if ($LASTEXITCODE -ne 0) { throw 'Maven install failed' }
mvn -pl "$Service-service" spring-boot:run '-Dspring-boot.run.profiles=local'
