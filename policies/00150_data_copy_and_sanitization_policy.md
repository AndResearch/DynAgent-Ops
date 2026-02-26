# Data Copy and Sanitization Policy

## Purpose

Define mandatory rules for production-derived data handling across `dev`, `staging`,
`prod-a`, and `prod-b`.

## Scope

- Database export/import (`promote-db` and equivalent manual operations)
- Backup dumps and temporary data files
- Access-control and operation audit records for environments

## Core Rules

1. `prod -> dev` database copy is strictly prohibited.
2. `dev` may only contain manually created or synthetic data.
3. Data copy into `staging` is allowed only when sanitization and sampling are applied in advance.
4. Raw production data must never be stored in `dev` or shared outside approved operators.
5. If sanitization is not completed or cannot be verified, the copy operation is blocked (No-Go).

## Approved Copy Paths

- `dev -> staging` (only with sanitization + sampling when source may include sensitive data)
- `prod-a|prod-b -> staging` (sanitization manifest required)
- `prod-a <-> prod-b` (operational lane sync; still requires approval and audit)

## Prohibited Copy Paths

- `prod-a -> dev`
- `prod-b -> dev`
- Any copy path not explicitly listed in "Approved Copy Paths"

## Sanitization Requirements

Before copying data to `staging`, the following must be defined and executed:

1. Masking target columns list (table/column level)
2. Masking method per column (irreversible replacement/hash/tokenization)
3. Sampling rule (target volume and strategy)
4. Validation checks (no raw sensitive values remain)

Minimum masking targets include:

- email
- phone number
- real name and address-like free text
- external credential or token fields

## Execution and Evidence

For each copy operation, keep an auditable record with:

- requester
- approver
- operator
- source/target environment
- purpose and ticket id
- masking job id and result
- sampling rule and resulting volume
- dump cleanup completion timestamp

Retention period:

- Keep records for `N` years (initial default: `5` years, adjustable by legal/compliance decision).

## Access History Requirements

Keep historical records of members who can access each environment (`dev`, `staging`, `prod-a`, `prod-b`):

- grant/revoke timestamp
- actor (who changed access)
- reason/ticket

Retention period:

- Keep access-change history for `N` years (same policy as operation evidence).

## Security and Operational Controls

1. Least-privilege access is mandatory.
2. Temporary artifacts (dumps, intermediate files) must be deleted after completion.
3. Reuse or secondary distribution of copied data is prohibited.
4. Policy exceptions require explicit approval and documented expiry date.

## External Communication Baseline

When asked whether production data is copied to development:

- Official answer: "Raw production data is not copied to `dev`. When needed for validation, only sanitized and sampled data is handled under approval and audit controls."
