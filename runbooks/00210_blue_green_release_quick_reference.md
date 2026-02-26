# 00210 Blue Green Release Quick Reference

## 1. Purpose

Blue/Green 本番リリース時に、最短で参照できる実行順（1-9）を示す。

## 2. Quick Steps (1-9)

1. Build and Push (linux/amd64 + explicit tag)
```bash
cd /path/to/Dynagent/Ops
make build TAG=20260218-150000-ab12cd3
# TAG未指定時は現在時刻+App/dev短縮SHAで自動生成
# make build
# build出力の BUILD_MANIFEST を控える
```

- build は `dev` でのみ実施する。`staging` / `prod` 系で新規 build しない。
- 昇格時は、`dev` で確定した同一 digest をそのまま使う。

2. Update digest in `App/helm/dynagent/values-cloud-dev.yaml` and commit

- `make build` で確定した `API_DIGEST` / `WORKER_DIGEST` を `values-cloud-dev.yaml` に反映して `App/dev` へ commit する。
- `build -> values更新(commit) -> deploy` を1セットとし、デプロイ後の追いコミットは禁止する。

3. Deploy to `dev`
```bash
make deploy ENV=dev MANIFEST=releases/builds/dev/<timestamp>-<sha>.json
```

- `deploy-backend.sh` はデプロイ後に `alembic upgrade head` を実行する。
- 失敗時はDB/アプリ整合が崩れるため、次ステップへ進まず解消を優先する。
- `make promote-deploy` は `MANIFEST` 指定に対応。digest直指定でも実行可能。
- `make deploy ... MANIFEST=...` で target 環境が manifest の build project と異なる場合、image は自動で target Artifact Registry へ昇格される。

4. Promote to `staging` and validate
```bash
make promote-deploy FROM=dev TO=staging MANIFEST=releases/builds/dev/<timestamp>-<sha>.json
# optional: data sync when needed
scripts/gcp/promote-db.sh dev staging
# if production-derived data is required for staging validation:
# scripts/gcp/promote-db.sh prod-a staging --sanitization-manifest releases/db-sanitization/prod-a-to-staging-<timestamp>.json
```

- `dev -> staging` は `make promote-deploy` を標準手順とし、`make deploy ENV=staging ...` の直接実行は避ける（緊急復旧時を除く）。
- `staging` 検証時は `/health` とログインに加えて、DB依存の主要画面（Team/Projects/Usage）を確認する。

5. Promote to standby production lane (`prod-a` or `prod-b`)
```bash
make promote-deploy FROM=staging TO=prod-b MANIFEST=releases/builds/dev/<timestamp>-<sha>.json
```

6. Validate standby lane
- `https://api.prod-a.<YOUR_DOMAIN>` or `https://api.prod-b.<YOUR_DOMAIN>`
- Confirm `/health`, login, and key user flow.

7. Manual public cutover (API first)
- Update Cloudflare `api.<YOUR_DOMAIN>` A record to standby IP.
- Observe 15-30 minutes (`5xx`, `p95`, login flow).
- If abnormal, rollback immediately to previous IP.

8. Promote Git branch (`staging -> main`) by PR

- `App` は `staging -> main` を PR で承認・マージする（直接 push/merge 禁止）。
- これはフロント公開更新トリガーのため、API切替完了後に実施する。

9. Confirm frontend auto-deploy and UI compatibility

- `dynagent.work`（Cloudflare auto deploy）が最新 `main` を配信していることを確認する。
- `Data -> Team / Projects / Usage` を含む主要UIを確認する。
- 原則順序は **API先行、フロント後行**。APIは後方互換（expand/contract）を維持する。

## 3. Detailed References

- Environment and policy: `Ops/platform/gke/00200_cloud_environment_operations.md`
- Data copy and sanitization policy: `Ops/policies/00150_data_copy_and_sanitization_policy.md`
- Production runbook: `Ops/runbooks/00220_blue_green_runbook.md`
- Manual cutover procedure: `Ops/runbooks/00230_blue_green_manual_cutover.md`
- Operation records: internal private runbook/log
