# Distribution and Local Config Policy

## Purpose

Define safe distribution boundaries and configuration sources for Cloud/On-Prem and Local Edition.

## Distribution Model

- Cloud/On-Prem distribution unit is `App` + `Ops`.
- Local Edition distribution unit is `App` only.
- `Ops` is not required for local personal/small-team usage.

## Config Source Separation

- Cloud/On-Prem:
  - Use Kubernetes environment variables from Helm values, Secret/ConfigMap, and Secret Manager.
  - Do not use developer machine `.env.local`.
- Local Edition:
  - Use shell environment variables.
  - Optionally use `App/.env.local` for local convenience.
  - Optionally use `~/.config/dynagent/config.toml` (or `DYNAGENT_CONFIG_FILE`).
  - Environment variable catalog is maintained in `App/docs/environment_variables.md`.

## Secret Handling Rules

- Never commit real secrets to git.
- `App/.env.local` and any `.env.*` (except examples) must be git-ignored.
- Commit only example files such as `App/.env.local.example`.
- Use personal low-privilege API keys for local development.

## Local Auth Policy

- `DYNAGENT_AUTH_REQUIRE_EMAIL_VERIFICATION` default is `true`.
- Cloud/On-Prem keeps default (`true`).
- Local Edition may set `false` in `App/.env.local` to allow rapid local iteration.

## Operational Notes

- `make run-api` may load `App/.env.local` only for local runtime.
- Deploy behavior (`Ops/make deploy`) is based on cluster-side env sources and is unaffected by local `.env.local`.
