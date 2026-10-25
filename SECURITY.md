# Security notice

This is **NOT** a production HR/PII processing system. It is deliberately simplified for teaching. The `local` security profile trusts `X-Demo-Role` and `X-Demo-Subject` request headers and is **unsafe on a public network**. The `aws` profile uses AWS Cognito-signed JWTs. Do not copy demo identities or credentials into real systems, and do not expose the local profile to the internet. See `docs/05-SECURITY.md` and `docs/15-PRODUCTION-HARDENING.md` for security trade-offs.
