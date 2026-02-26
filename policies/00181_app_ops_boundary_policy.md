# App/Ops Boundary Policy

## Purpose

Clarify repository responsibilities for on-prem operators.

## Ownership

- `App`:
  - application source code
  - tests
  - Helm chart source used by the application release
- `Ops`:
  - operational runbooks
  - operational policies
  - operational helper scripts (`scripts/`)

## Script Placement Rule

- Put operational automation in `Ops/scripts`.
- Do not place environment operation scripts in `App`.
- Keep `App` focused on application build/test/runtime concerns.

## Integration Rule

- `Ops` may invoke `App` standard entrypoints (for example `make` targets) when needed.
- `Ops` must not require internal-only environment matrix or secrets in public templates.

