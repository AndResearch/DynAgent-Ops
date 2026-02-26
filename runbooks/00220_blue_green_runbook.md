# 00220 Blue Green Runbook (Production)

## 1. Purpose

- 本番データで最終検証しつつ、切替リスクを最小化する。
- `api.<YOUR_DOMAIN>` の停止時間を最小化する。
- 失敗時に即時ロールバックできる状態を維持する。

## 2. Scope

- 対象は本番環境のみ（`prod-a` / `prod-b`）。
- `dev` / `staging` の通常開発フローは `00200` に従う。

## 3. Terms

- `Active`: 現在ユーザーアクセスを受ける本番系（`prod-a` または `prod-b`）。
- `Standby`: 次回リリース先の待機本番系。
- `Blue/Green`: `Active` / `Standby` を切り替える運用。

## 4. Topology (Fixed)

- Project:
  - `<YOUR_PROJECT_PROD_A>`
  - `<YOUR_PROJECT_PROD_B>`
- Cluster (each project):
  - API: `<YOUR_API_CLUSTER_NAME>`
  - Worker: `<YOUR_WORKER_CLUSTER_NAME>`
- Host:
  - 公開: `api.<YOUR_DOMAIN>`
  - 検証用: `api.prod-a.<YOUR_DOMAIN>`, `api.prod-b.<YOUR_DOMAIN>`
- Database:
  - `prod-a` / `prod-b` は系統分離（それぞれ独立Cloud SQL）

## 5. Hard Rules

- `Active` 系へ直接デプロイしない。
- 本番切替は必ず手動実施（自動切替禁止）。
- DB同期で `Standby` を作る場合は、必ず手順書どおりに行う。
- DBマイグレーションは `expand/contract` の後方互換方式のみ許可する。
- 切替直後に旧 `Active` を削除しない。

## 6. Preconditions

- `Standby` に対象バージョンのイメージが存在する。
- `Standby` の Ingress と TLS が有効。
- Cloud SQL接続、Secret Manager、Workload Identity が `Standby` で動作。
- 監視とアラートが `Standby` を対象に確認可能。

## 7. Standard Release Flow

### 7.1 Prepare Variables

```bash
export ACTIVE_ENV="prod-a"      # or prod-b
export STANDBY_ENV="prod-b"     # or prod-a
export API_DIGEST="sha256:..."
export WORKER_DIGEST="sha256:..."
```

### 7.2 Deploy to Standby

- `staging` で承認済み digest（`dev` でbuild済みの同一digest）を `Standby` へ反映する。
- 人間の手動デプロイは `make deploy ...` を使用する（`deploy-backend.sh` 直実行はCI用途のみ）。
- `make deploy` はデプロイ前に quota/capacity precheck を実行し、不足時は fail-fast で停止する。
- `make deploy` はデプロイ前に Alembic schema drift precheck を実行し、履歴/実体ズレ検知時は fail-fast で停止する。
- `make deploy` は migration 実行前に Alembic が単一headであることを検査し、複数head時は fail-fast で停止する。
- `Standby` は `ROLLOUT_MODE=quota-safe`（`maxSurge=0/maxUnavailable=1`）を使用する。
- `make deploy` はデプロイ後に `alembic upgrade head` を自動実行する。失敗時は切替工程へ進まない。
- `make deploy ... MANIFEST=...` で target project が manifest の build project と異なる場合、deploy前に image が target Artifact Registry へ自動昇格される（`linux/amd64` 固定）。

```bash
scripts/gcp/promote-values.sh staging "$STANDBY_ENV"
make promote-deploy FROM=staging TO="$STANDBY_ENV" MANIFEST=releases/builds/dev/<timestamp>-<sha>.json
```

### 7.3 Sync Standby DB (when required)

- `Standby` DBへ同期が必要な場合のみ実施する。
- 本操作はターゲットDB再作成を伴うため、事前承認を必須にする。

```bash
scripts/gcp/promote-db.sh "$ACTIVE_ENV" "$STANDBY_ENV" --allow-prod-sync
```

### 7.4 Validate Standby

- 最低確認:
  - `/health` が連続成功
  - ログイン/主要機能/外部連携
  - エラーレート、p95遅延
- 検証は `api.prod-*.dynagent.work` に対して実施する。
- `kubectl get events -n dynagent --field-selector type=Warning,reason=FailedScheduling` を確認し、残件があれば No-Go とする。
- `Pending` Pod が残る場合は切替禁止。quota不足 or cluster capacity不足を優先調査する。

### 7.5 Switch Traffic (Manual)

- `api.<YOUR_DOMAIN>` の切替は手動で行う。
- 手順は `00230_blue_green_manual_cutover.md` に従う。

### 7.6 Promote Git (`staging -> main`) and frontend

- API切替が安定した後に `App` の `staging -> main` PR を承認・マージする。
- `dynagent.work` のフロントは `main` 連動の Cloudflare auto deploy で更新される。
- 先にフロントだけ更新しない（新フロント -> 旧API 互換欠如を避ける）。
- 原則は **API先行、フロント後行**。

### 7.7 Observe

- 切替後 15-30分は重点監視:
  - 5xx
  - レイテンシ
  - 認証など重要機能
  - `dynagent.work` の主要UI（`Team` / `Projects` / `Usage`）整合

### 7.8 Standby Follow-up Sync (N/N)

- 目的: 切替後に旧 `Active`（新 `Standby`）を同一バージョンへ追随させ、`prod-a` / `prod-b` のアプリ差分を残さない。
- 実施タイミング: `7.7 Observe` で安定確認後、同一作業枠内で実施する。
- 適用内容: 切替済み `Active` と同じ `API_DIGEST` / `WORKER_DIGEST`（または同じ manifest）を、新 `Standby` へ反映する。
- 注意:
  - 追随同期でも `make deploy` の precheck（drift/quota）に失敗したら停止し、原因解消まで次工程へ進まない。
  - 追随同期後に `api.prod-*.dynagent.work` で最低限のヘルス/主要導線を再確認する。

```bash
# 例: Active=prod-b へ切替済み後、Standby=prod-a を同版へ追随
make promote-deploy FROM=staging TO="$STANDBY_ENV" MANIFEST=releases/builds/dev/<timestamp>-<sha>.json
# または digest 明示
make deploy ENV="$STANDBY_ENV" API_DIGEST="$API_DIGEST" WORKER_DIGEST="$WORKER_DIGEST"
```

## 8. Rollback

- ロールバック条件に該当したら即時実行:
  - Cloudflare `api.<YOUR_DOMAIN>` を旧 `Active` IPへ戻す。
  - 旧 `Active` の正常性を確認。
- 変更内容と時刻をインシデントログへ記録。

## 8.1 Troubleshooting Notes

- `rollout status failed` 時の切り分け優先順:
  1. `kubectl get pods -n dynagent`
  2. `kubectl describe pod -n dynagent <pod>`
  3. `kubectl get events -n dynagent --field-selector type=Warning --sort-by=.lastTimestamp`
- `FailedScheduling` が出ても、同時に `ImagePullBackOff` がある場合は image pull 失敗を優先して調査する。
- `ImagePullBackOff` の典型原因:
  - target project 側 Artifact Registry に対象 digest が存在しない
  - ノードの pull 権限不足

- Alembic precheck で `current heads in DB are multiple` の場合は No-Go。
  - 先に Pod 内で `alembic upgrade head` を実行し、`alembic current` が単一 head へ収束したことを確認してから deploy を再実行する。

## 9. DB Migration Policy

- 必須:
  - `expand` で新旧アプリが同時動作可能な状態を作る。
  - 切替完了後に `contract` で不要スキーマを削除。
  - デプロイごとに `alembic upgrade head` を実行し、未適用リビジョンを残さない。
- 禁止:
  - 切替前に旧アプリを壊す非互換DDL。

## 10. Decommission Policy

- 旧 `Active` は削除しない。
- 次回リリース成功まで `Standby` として保持。
- コスト最適化で縮退する場合は「削除」ではなく最小構成化を優先。

## 11. SLA Input

- 停止時間として計上する:
  - 切替失敗により `api.<YOUR_DOMAIN>` が不達
  - 切替後に主要機能が提供不能
- 除外条件:
  - 事前告知済みメンテ
  - 外部依存障害（Cloudflare, GCP広域障害, LLM API障害）

## 12. Operator Checklist

1. `Standby` のデプロイ完了
2. （必要時）`Standby` DB同期完了
3. `FailedScheduling`/`Pending` が解消済み（未解消なら No-Go）
4. `Standby` で機能確認完了
5. 手動切替実施時刻を記録
6. API切替後に `staging -> main` PR をマージ（フロント更新）
7. `dynagent.work` のUI整合確認（`Team` / `Projects` / `Usage`）
8. 切替後の監視確認
9. 新 `Standby` へ同版追随（N/N同期）を完了
10. 問題なければ「旧ActiveをStandbyとして維持」
