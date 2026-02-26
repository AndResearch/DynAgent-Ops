# 00200 Cloud Environment Operations

## 1. Goal

- `prod-a` / `prod-b` のBlue/Greenで本番可用性を高く維持する。
- `dev` / `staging` は必要時のみ起動し、課金を最小化する。
- 昇格経路を `prod-a|prod-b -> dev -> staging -> prod-a|prod-b` に固定する。

## 2. Environment Topology

| Env | GCP Project | API Cluster | Worker Cluster | Domain |
|-----|-------------|-------------|----------------|--------|
| dev | <YOUR_PROJECT_DEV> | <YOUR_API_CLUSTER_NAME> | <YOUR_WORKER_CLUSTER_NAME> | api.dev.<YOUR_DOMAIN> |
| staging | <YOUR_PROJECT_STAGING> | <YOUR_API_CLUSTER_NAME> | <YOUR_WORKER_CLUSTER_NAME> | api.staging.<YOUR_DOMAIN> |
| prod-a | <YOUR_PROJECT_PROD_A> | <YOUR_API_CLUSTER_NAME> | <YOUR_WORKER_CLUSTER_NAME> | api.prod-a.<YOUR_DOMAIN> |
| prod-b | <YOUR_PROJECT_PROD_B> | <YOUR_API_CLUSTER_NAME> | <YOUR_WORKER_CLUSTER_NAME> | api.prod-b.<YOUR_DOMAIN> |
| public | (Cloudflare) | - | - | api.<YOUR_DOMAIN> |

- `api.<YOUR_DOMAIN>` は常に Active 側（`prod-a` または `prod-b`）へ向ける。

## 3. Operational Policy

Reference:
- `Ops/policies/00150_data_copy_and_sanitization_policy.md`

### 3.1 Availability Policy

- 本番は `prod-a` / `prod-b` の2系統を維持する。
- `dev` / `staging` は利用時のみ起動。未使用時はクラスタ削除で課金停止。

### 3.2 Promotion Policy

- 許可:
  - `prod-a -> dev`
  - `prod-b -> dev`
  - `dev -> staging`
  - `staging -> prod-a`
  - `staging -> prod-b`
- 禁止:
  - `dev -> prod-a|prod-b` 直行（`staging` を必須化）

### 3.3 Deployment Policy

- 明示タグのみ（`latest` 禁止）。
- 本番反映前に `staging` で動作確認。
- 本番切替（`api.<YOUR_DOMAIN>` の向き変更）は必ず手動で実施。
- 人間の手動デプロイは `make deploy ...` のみ許可する（`scripts/gcp/deploy-backend.sh` 直実行は禁止）。
- `scripts/gcp/deploy-backend.sh` 直実行は将来の自動化/CI用途に限定する。
- イメージ build は `dev` でのみ実施し、`staging` / `prod-a` / `prod-b` での build を禁止する。
- `staging` / `prod-a` / `prod-b` への反映は、`dev` で確定した同一 `API_DIGEST` / `WORKER_DIGEST` を昇格利用する。
- 本番手動切替後は、安定確認ののち旧 `Active`（新 `Standby`）にも同一 digest を反映し、`prod-a` / `prod-b` のアプリ版を一致させる（Standby追随/N/N同期）。

### 3.4 Local Runtime Safety Policy

- ローカル実行は `make ...` または `.venv/bin/python -m ...` のみを許可する。
- `python` / `pytest` の生実行は原則禁止（PATH差異で依存不整合が起きるため）。
- `.venv` は Python 3.11 固定とし、`make doctor` で毎回検査する。
- `grpc` / `protobuf` / `pytest_asyncio` を含む依存セット（`.[dev,web]`）を標準にする。

### 3.5 Config Governance Policy

運用ミス防止のため、設定変更領域を以下に分離する。

| 区分 | 変更主体 | 対象 |
|------|----------|------|
| Manual-only | 人間のみ | `helm/dynagent/values-cloud-*.yaml`（CORS、ドメイン、image tag/digest、project/env固有値） |
| AI-editable | AI可（レビュー前提） | `src/**`, `tests/**`, 一般ドキュメント、フロント実装 |

- 手動運用用のローカル保管先として `<YOUR_LOCAL_CONFIG_PATH>` を使用する。
- CORS は `DYNAGENT_CORS_ALLOWED_ORIGINS` を環境別に明示設定し、`*` は禁止する。
- `dev` はローカルフロント起点運用のため `http://127.0.0.1:4173` / `http://localhost:4173` を許可する。
- `staging` / `prod-a` / `prod-b` は Cloudflare フロント（`https://dynagent.work` 等）のみ許可する。

## 4. Standard Commands

### 4.1 Start/Stop Clusters

```bash
# 起動
scripts/gcp/start-clusters.sh dev
scripts/gcp/start-clusters.sh staging
scripts/gcp/start-clusters.sh prod-a
scripts/gcp/start-clusters.sh prod-b

# 停止（削除）
scripts/gcp/stop-clusters.sh dev
scripts/gcp/stop-clusters.sh staging
scripts/gcp/stop-clusters.sh prod-a
scripts/gcp/stop-clusters.sh prod-b
```

### 4.2 Deploy Backend

```bash
make build TAG=20260218-150000-ab12cd3
# TAG未指定時は現在時刻+App/dev短縮SHAで自動生成
make build
# build完了時に BUILD_MANIFEST=Ops/releases/builds/dev/<timestamp>-<sha>.json を出力

# buildで確定したdigestを values-cloud-dev.yaml へ反映して commit（必須）
# app.image.digest / worker.image.digest を更新し、App/dev へコミット

# build manifest 参照で deploy（推奨）
make deploy ENV=dev MANIFEST=releases/builds/dev/<timestamp>-<sha>.json

# digest 明示指定でも deploy 可能
make deploy ENV=dev API_DIGEST=sha256:... WORKER_DIGEST=sha256:...
make deploy ENV=prod-a API_DIGEST=sha256:... WORKER_DIGEST=sha256:...
make deploy ENV=prod-b API_DIGEST=sha256:... WORKER_DIGEST=sha256:...

# ロールアウト戦略上書き（quota-safe: maxSurge=0/maxUnavailable=1）
make deploy ENV=staging API_DIGEST=sha256:... WORKER_DIGEST=sha256:... ROLLOUT_MODE=quota-safe
```

- `make deploy` はデプロイ後に `alembic upgrade head` を自動実行する。
- `make deploy` は migration 実行前に `alembic heads` を検査し、複数head検知時は fail-fast で停止する（merge migration 完了まで進行禁止）。
- `make deploy` は Helm 実行前に Alembic schema drift precheck（`current/heads` と pending migration の `create_table` 対象実在照合）を実行し、ドリフト検知時は fail-fast で停止する。
- `make deploy` は Helm 実行前に quota/capacity precheck を実行し、不足時は fail-fast で停止する。
- `ROLLOUT_MODE`:
  - `auto`（デフォルト）: `dev/staging=default`, `prod-a/prod-b=quota-safe`
  - `default`: `maxSurge=1`, `maxUnavailable=0`
  - `quota-safe`: `maxSurge=0`, `maxUnavailable=1`
- マイグレーションが失敗した場合、そのデプロイは未完了として扱い、原因解消まで次の昇格へ進まない。
- DDLは `expand/contract` の後方互換方針を必須とする（新旧アプリ同時稼働を壊さない）。
- `make deploy` は `MANIFEST` または `API_DIGEST` / `WORKER_DIGEST` のどちらかを必須とする（`API_TAG` / `WORKER_TAG` は受け付けない）。
- `make build` は機械可読ログ（build manifest）を `Ops/releases/builds/dev/` へ出力する。
- `make deploy` は機械可読ログ（deploy record）を `Ops/releases/deploys/<env>/` へ出力する。
- `Ops/releases/builds/dev/` / `Ops/releases/deploys/<env>/` は監査証跡であり、原則削除しない。
- 失敗実行時は通常 record が生成されないため、JSON が存在するものは「完了した実行」の履歴として扱う。
- 一時的に Git と deploy が乖離した履歴も削除せず保持し、最終的に `values-cloud-<env>.yaml` と最新 deploy record の一致で現行状態を判断する。
- `dev -> staging` の昇格反映は `make promote-deploy FROM=dev TO=staging ...` を必須とし、`make deploy ENV=staging ...` の直接利用は原則禁止（緊急復旧時のみ）。
- `make deploy ENV=<target> MANIFEST=...` 実行時、manifest の `project` が `<target>` と異なる場合は、deploy前に image を target プロジェクトの Artifact Registry へ自動昇格してから適用する。
- image昇格時の pull platform は `linux/amd64` 固定（Apple Silicon 環境での `no matching manifest for linux/arm64` 回避）。
- `make build` は `ENV=dev` のみ許可する（`staging` / `prod-a` / `prod-b` での build は失敗させる）。
- `build -> values-cloud-<env>.yaml の digest更新+commit -> deploy` を必須とし、デプロイ後の追いコミット運用を禁止する。
- `values-cloud-<env>.yaml` の記載値と、実際の稼働イメージタグ/digest を一致させ、環境調査時に乖離を作らない。
- rollout失敗時に `FailedScheduling` が出た場合は、quota/capacity起因として扱い、切替工程へ進まない。

### 4.3 Promote + Deploy

```bash
make promote-deploy FROM=prod-a TO=dev API_DIGEST=sha256:... WORKER_DIGEST=sha256:...
make promote-deploy FROM=prod-b TO=dev API_DIGEST=sha256:... WORKER_DIGEST=sha256:...
make promote-deploy FROM=dev TO=staging API_DIGEST=sha256:... WORKER_DIGEST=sha256:...
make promote-deploy FROM=staging TO=prod-a API_DIGEST=sha256:... WORKER_DIGEST=sha256:...
make promote-deploy FROM=staging TO=prod-b API_DIGEST=sha256:... WORKER_DIGEST=sha256:...
# または MANIFEST 指定（推奨）
make promote-deploy FROM=dev TO=staging MANIFEST=releases/builds/dev/<timestamp>-<sha>.json
make promote-deploy FROM=staging TO=prod-b MANIFEST=releases/builds/dev/<timestamp>-<sha>.json
```

### 4.4 Promote DB Data

```bash
# devデータをstagingへ
scripts/gcp/promote-db.sh dev staging

# 本番系データをstagingへ（マスキング/サンプリングmanifest必須）
scripts/gcp/promote-db.sh prod-a staging --sanitization-manifest releases/db-sanitization/prod-a-to-staging-<timestamp>.json
scripts/gcp/promote-db.sh prod-b staging --sanitization-manifest releases/db-sanitization/prod-b-to-staging-<timestamp>.json

# prod系統間DB同期（破壊的、明示許可必須）
scripts/gcp/promote-db.sh prod-a prod-b --allow-prod-sync
scripts/gcp/promote-db.sh prod-b prod-a --allow-prod-sync
```

- `prod -> dev` のDBコピーは禁止（詳細は `Ops/policies/00150_data_copy_and_sanitization_policy.md`）。
- `prod -> staging` は `--sanitization-manifest` を必須とし、マスキング/サンプリング証跡がない場合は実行禁止。
- `dev -> staging` コピー時は、機微データを含みうる場合にマスキング/サンプリングを必須とする。
- `staging -> prod-a|prod-b` へのDBコピーは禁止（アプリ昇格で反映）。
- `prod-a <-> prod-b` のDB同期はターゲットDB再作成を伴うため、作業時間帯と承認を必須にする。

### 4.5 Local Bootstrap / Doctor

```bash
make bootstrap
make doctor
make test
```

`make doctor` が失敗した場合は、`.venv` のPythonバージョン不一致または依存不足を優先的に疑う。

### 4.6 Optional Shell Guard (Recommended)

誤操作防止のため、`~/.zshrc` に以下を追加して `python` / `pytest` の生実行を弾く。

```bash
# BEGIN DYNAGENT PYTHON GUARD
python() {
  echo "Use .venv/bin/python -m ... or make ..." >&2
  return 1
}
pytest() {
  echo "Use make test or .venv/bin/python -m pytest" >&2
  return 1
}
# END DYNAGENT PYTHON GUARD
```

### 4.7 Future CI Guard Memo (TODO)

CI導入時に必ず追加するガード（備忘）:

- `values-cloud-*.yaml` に `DYNAGENT_CORS_ALLOWED_ORIGINS` が存在することを検証。
- `staging/prod` で `*` またはローカルoriginが混入したら失敗。
- Manual-only領域（`values-cloud-*.yaml`）の変更は CODEOWNERS で人間承認必須にする。

### 4.8 Local Frontend (Dev Only)

- ローカルフロント起動は `dev` API 接続時のみ許可する。
- `VITE_API_URL` を未指定にすると `http://localhost:8000` へプロキシされるため、GKE `dev` API 接続時は必ず明示する。
- `staging` / `prod-a` / `prod-b` 向けにローカルフロントを常用しない。
- 人間の手動起動は `make frontend-dev` のみ許可する（`VITE_API_URL=... npm run dev` 直実行は禁止）。

```bash
cd App
make frontend-dev
```

## 5. DB Separation Policy (Production)

- `prod-a` / `prod-b` はDBを分離する。
- 目的:
  - ロールバック時に旧系統DBを維持しやすくする。
  - 系統ごとの検証・切替を明確化する。
- 注意:
  - 系統間データ同期は手順化しないとデータ差分が発生する。
  - `prod-a <-> prod-b` 同期の直後に必ず検証を行う。

## 6. SLA Input: Downtime Conditions

SLA文書に、少なくとも以下の停止条件を記載する。

- GKE Control Plane または Node 障害で `dynagent` Pod が復旧しない。
- Cloud SQL 障害で API が継続的に `5xx` を返す。
- DNS/TLS 不整合で `api.<YOUR_DOMAIN>` が到達不能。
- 依存先（LLM APIなど）の長時間障害で主要機能が提供不能。
- 事前告知済みメンテナンス（除外条件として明記）。

## 7. Required Observability

- `/health` 成功率
- `5xx` レート
- p95 レイテンシ
- デプロイイベント（誰がいつどの経路で昇格したか）
- Cloudflare切替イベント（切替時刻、切替前後の向き）

## 8. Runbook Checklist

### 8.1 New Development (from prod baseline)

1. `make bootstrap`
2. `make doctor`
3. `scripts/gcp/promote-values.sh prod-a dev` または `scripts/gcp/promote-values.sh prod-b dev`
4. `make deploy ENV=dev`（devデータは手作り/合成データのみ）
5. 開発・検証

### 8.2 Release Candidate

1. `make promote-deploy FROM=dev TO=staging MANIFEST=releases/builds/dev/<timestamp>-<sha>.json`
2. `scripts/gcp/promote-db.sh dev staging`
3. `staging` で受け入れ確認

### 8.3 Production Release

1. `make promote-deploy FROM=staging TO=<prod-a|prod-b> MANIFEST=releases/builds/dev/<timestamp>-<sha>.json`
2. `api.prod-*.dynagent.work` で検証
3. `api.<YOUR_DOMAIN>` は手動で切替（`00230_blue_green_manual_cutover.md`）
4. `App` の `staging -> main` を PR でマージし、Cloudflare frontend auto deploy を待つ
5. `dynagent.work` で主要UI（`Team` / `Projects` / `Usage`）を確認する

- 原則順序は **API先行、フロント後行** とする（新フロント -> 旧API の不整合を避ける）。
- API更新は後方互換（expand/contract）を維持し、旧フロントからのリクエストを継続処理可能にする。

### 8.4 Go/No-Go (Quota Aware)

1. `make deploy` が precheck を通過している（quota不足failがない）
2. `kubectl get events -n dynagent` で `FailedScheduling` が継続していない
3. `Pending` Pod が残っていない
4. いずれかが不成立なら No-Go（切替禁止）

## 9. Manual Tasks (Owner: User)

以下はCloudflare側作業のため手動実施が必要。

1. DNS `A` レコード更新:
   - `api.dev.<YOUR_DOMAIN>` -> dev Ingress 固定IP
   - `api.staging.<YOUR_DOMAIN>` -> staging Ingress 固定IP
   - `api.prod-a.<YOUR_DOMAIN>` -> prod-a Ingress 固定IP
   - `api.prod-b.<YOUR_DOMAIN>` -> prod-b Ingress 固定IP
   - `api.<YOUR_DOMAIN>` -> Active側 Ingress 固定IP
2. 各レコードの Proxy 設定（ON/OFF）を統一ルールで固定。
3. 反映後、ManagedCertificate が `Active` になったことを確認。
