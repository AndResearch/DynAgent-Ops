# Scripts (Public Ops)

`scripts/` is for operational helper scripts, not application source code.

Current public scripts:

- `public/check-public-safety.sh`

Guideline for on-prem operators:

- add customer-environment operational scripts under `scripts/` in this repository
- keep application implementation in `App`
- call `App` standard interfaces (e.g. `make`) from ops scripts when integration is required

