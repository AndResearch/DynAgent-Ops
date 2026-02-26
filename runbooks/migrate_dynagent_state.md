# DynAgent State Migration

This document describes how to migrate legacy state into the new `.dynagent/` layout.

## What it migrates

- `teammaker.db` or `dynagent.db` in the project root
  - moved to `.dynagent/sqlite.db`
- `team.yaml` in the project root
  - moved to `.dynagent/sessions/<timestamp>_legacy.yaml`

The script is idempotent: if the target already exists, it leaves it untouched.

## Usage

Run the script from the project root.

Dry run:

  python scripts/migrate_dynagent_state.py --dry-run

Apply:

  python scripts/migrate_dynagent_state.py

## Notes

- The destination session YAML name uses the legacy file's modification time (UTC)
  and the `_legacy` suffix.
- If you already have `.dynagent/sqlite.db`, the DB migration is skipped.
