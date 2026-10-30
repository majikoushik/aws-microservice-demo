# 09 — AWS Cognito: create roles, obtain JWT and call the live API

**Important:** Cloud uses real JWT tokens and **does not seed local H2 employees**. You must create synthetic test users/groups, then insert employee profiles with the users' Cognito `sub` values using the HR token.

## 1 — Read outputs

```bash
terraform -chdir=infrastructure/terraform output -raw cognito_user_pool_id
terraform -chdir=infrastructure/terraform output -raw cognito_client_id
terraform -chdir=infrastructure/terraform output -raw api_base_url
```

Set environment variables in your shell: `POOL_ID`, `CLIENT_ID`, `API_BASE`, `AWS_REGION`. All commands below use placeholders, not stored secrets. Use AWS CLI user-pool administration in an authorized account.

## 2 — Create an HR user (synthetic)

```bash
aws cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username hr-demo \
 --message-action SUPPRESS --region "$AWS_REGION"
aws cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username hr-demo \
 --password 'PUT_A_STRONG_NONREUSED_PASSWORD_HERE' --permanent --region "$AWS_REGION"
aws cognito-idp admin-add-user-to-group --user-pool-id "$POOL_ID" \
 --username hr-demo --group-name HR --region "$AWS_REGION"
```

Repeat for `alice-demo` in `EMPLOYEE` and `maria-demo` in `MANAGER`. Use distinct, strong passwords and avoid storing them in source control or terminal history on shared machines. For a classroom, use Cognito hosted OAuth flows rather than sharing a password across students.

## 3 — Fetch access tokens for each sample identity

```bash
aws cognito-idp admin-initiate-auth --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
 --auth-flow ADMIN_USER_PASSWORD_AUTH \
 --auth-parameters USERNAME=hr-demo,PASSWORD='YOUR_PASSWORD' \
 --query 'AuthenticationResult.AccessToken' --output text --region "$AWS_REGION"
```

This admin auth flow is enabled only as a **lab convenience**. The production recommendation is Authorization Code + PKCE for browser/mobile clients, MFA, identity lifecycle policy and no plain-password CLI scripts.

Do not send the ID token as the bearer token. **Use the AccessToken** returned by Cognito. The token includes `sub` and `cognito:groups`.

## 4 — Get identity-subject identifiers

```bash
aws cognito-idp admin-get-user --user-pool-id "$POOL_ID" \
 --username alice-demo --region "$AWS_REGION"
```

Locate the `sub` user attribute, e.g. `9fbc...-...`. Repeat for `maria-demo`. The values are Cognito identifiers, not local demo subject strings.

## 5 — HR creates employee profiles

```bash
curl -X POST "$API_BASE/api/employees" \
  -H "Authorization: Bearer $HR_ACCESS_TOKEN" -H 'Content-Type: application/json' \
  -d '{"identitySubject":"ALICE_SUB","name":"Alice Demo","email":"alice@example.test","department":"Engineering","managerSubject":"MARIA_SUB"}'
```

Also create the manager's profile for clarity, with their own `identitySubject` and no manager. Record the generated `id` returned for Alice. When she logs in, `JwtAuthenticationToken.getName()` is her Cognito `sub`, which matches the employee profile. The manager `sub` grants access to Alice's record and approval.

## 6 — Test basic authorization

```bash
curl -H "Authorization: Bearer $ALICE_ACCESS_TOKEN" "$API_BASE/api/employees/ALICE_ID"
curl -H "Authorization: Bearer $ALICE_ACCESS_TOKEN" "$API_BASE/api/employees/MANAGER_ID"
```

First should be 200. Second should be 403 (unless the manager record identity matches or a role permits access). Manager can access Alice. HR can list and modify employee profiles.

## 7 — Approve a real AWS test leave

Create a request as Alice with dates in the future, save returned request ID, approve as Maria, then read Alice's balance and examine CloudWatch/SQS/DynamoDB as described in [08](08-AWS-DEPLOYMENT.md).

### Pitfall: group name mismatch

Terraform creates uppercase Cognito groups `EMPLOYEE`, `MANAGER`, `HR`. The Java `JwtAuthenticationConverter` maps group names into matching `ROLE_*` authorities. Missing group assignment → 403 even when JWT is valid.

### Pitfall: token expiration

Access tokens expire. Obtain a fresh token when testing later. If you receive 401 before any controller log, inspect Cognito issuer, API Gateway audience/client ID, expired token or use of ID token.
