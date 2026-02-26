# SECURITY

## Scope

This document defines what must never be included in the public `Ops` repository.

## Prohibited in Public Ops

- Real environment identifiers (`dev`, `staging`, `prod-a`, `prod-b`) tied to real assets.
- Real GCP project IDs, cluster names, service account addresses, bucket names.
- Real domains, IP addresses, or DNS cutover details.
- Deployment/build/promotion records and internal operation logs.
- Any real secret value, credential, token, key, or connection string.

## Required Public Style

- Replace concrete values with placeholders:
  - `<YOUR_PROJECT_ID>`
  - `<YOUR_CLUSTER_NAME>`
  - `<YOUR_DOMAIN>`
  - `<YOUR_SERVICE_ACCOUNT_EMAIL>`
- Distribute examples only (`*.example`, template YAML).
- Avoid `latest` image tag. Use explicit version tags and digest guidance.

## Repository Split Baseline

- Public repository: `Ops`
- Internal repository: `Ops-internal`

Internal-only directories from the current baseline:

- `releases/`
- `archives/`
- `scripts/gcp/`

## Validation

- Run `make check-public-safety` before publishing changes to `Ops`.
- In CI for public repository, run `scripts/public/check-public-safety.sh` on every PR.

