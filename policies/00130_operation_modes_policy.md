# Operation Modes and Approval Gates

## Purpose

Define how the system behaves in three operational modes, including which steps
require human approval.

## Modes

- Mode 1 (Read-only): investigation and suggestions only. No code or environment
  changes are allowed.
- Mode 2 (Staging-autonomous, default): code changes, tests, and staging deploy
  run without approval. Production merge/deploy requires human approval.
- Mode 3 (Full-autonomous): end-to-end execution including production merge and
  deploy without approval.

## Approval Gates (by phase)

Legend:
- "Auto" = can run without human approval.
- "Approve" = requires human approval.
- "Blocked" = not allowed in this mode.

| Phase | Scope | Mode 1 | Mode 2 | Mode 3 |
| --- | --- | --- | --- | --- |
| 1. Requirements intake | Issue analysis, clarification questions, task breakdown | Auto | Auto | Auto |
| 2. Planning | Impact analysis, test strategy, scope estimate | Auto | Auto | Auto |
| 3. Implementation | Patch generation and local changes | Blocked | Auto | Auto |
| 4. Verification | Test selection and execution | Blocked | Auto | Auto |
| 5. Review support | Risk analysis and test suggestions | Auto | Auto | Auto |
| 6. PR preparation | Draft PR content and changelog | Blocked | Auto | Auto |
| 7. Recovery | Retry guidance and minimal fix suggestions | Auto | Auto | Auto |

## Environment Gates

| Action | Mode 1 | Mode 2 | Mode 3 |
| --- | --- | --- | --- |
| Modify working tree | Blocked | Auto | Auto |
| Commit changes | Blocked | Auto | Auto |
| Deploy to staging | Blocked | Auto | Auto |
| Merge to production | Blocked | Approve | Auto |
| Deploy to production | Blocked | Approve | Auto |

## Notes

- "Auto" still logs actions and produces a review summary for traceability.
- Mode 2 is the default to keep production changes under human control.
- Phase 1 detailed guidance lives in `Ops/runbooks/00140_phase1_workflow_guide.md`.
