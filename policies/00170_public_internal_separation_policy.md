# Public/Internal Repository Separation Policy

## Purpose

Define the final split policy between:

- `Ops` (public distribution repository)
- `Ops-internal` (internal-only operations repository)

This policy is based on Request 00104 decision (2026-02-26).

## Repository Roles

### `Ops` (public)

- On-prem operators can read and use without internal company context.
- Contains templates, generic procedures, and placeholder-based examples.
- Must not contain internal environment identifiers or operation history.

### `Ops-internal`

- Internal operations source of truth.
- Contains real environment identifiers, deployment/build records, and internal runbooks.
- Access is restricted to internal operators.

## Classification Rules

### Public-allowed

- Abstract runbooks and checklists that do not include real values.
- `.example`-style templates.
- Safety and policy documents describing rules without concrete IDs.
- Helm artifacts prepared for distribution (placeholder values only).

### Internal-only

- Real domains, project IDs, cluster names, service account identifiers.
- Build/deploy/promotion history records.
- Incident/cutover logs and internal postmortems.
- Scripts coupled to real internal environment matrix.

## Current Path Baseline

- Public candidate:
  - `README.md`
  - `Makefile` (after public-target cleanup)
  - `policies/`
  - `runbooks/` (placeholderized copies)
  - `platform/` (publicized copies)
- Internal fixed:
  - `releases/`
  - `archives/`
  - `scripts/gcp/`

## Migration Phases

1. Phase 1 (sync):
   - Keep `App/helm/dynagent` as source.
   - Sync copy to `Ops/helm/dynagent` for distribution.
2. Phase 2 (reference switch):
   - Update runbooks/scripts to reference `Ops/helm/dynagent`.
3. Phase 3 (source transfer):
   - Move chart source ownership to `Ops/helm/dynagent`.

## Mandatory Guards

- Secret scan (`gitleaks` or equivalent).
- Deny-pattern scan for concrete environment identifiers.
- Packaging checks to ensure internal directories are excluded from public release.
- History audit and remediation workflow (history rewrite + key rotation when needed).

