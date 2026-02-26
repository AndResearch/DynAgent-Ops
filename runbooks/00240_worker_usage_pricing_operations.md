# Worker Usage/Pricing Operations (00820)

## Purpose

`model_pricing_catalog` と `EXCHANGE_RATES_TO_USD` の運用手順、および usage limit 監視基準を定義する。

## Pricing Catalog Seed

初期投入・更新は `App` で実行する。

```bash
cd App
make seed-pricing-catalog-dry-run
make seed-pricing-catalog
```

`deactivate` が必要な場合は以下を使う。

```bash
cd App
.venv/bin/python -m dynagent.scripts.seed_model_pricing_catalog --deactivate-missing
```

## Pricing Change Procedure

1. `App/src/dynagent/services/cost_tracker.py` の `CostTracker.PRICING` を更新
2. dry-run で差分確認
3. seed 実行
4. `GET /api/users/me/usage/pricing-catalog` で反映確認
5. `Worklog/requests/00820_Worker_Pod_Resource_Tiers.md` の更新履歴に記録

## Active Switch Procedure

1. 新単価を seed で投入
2. 旧エントリを `--deactivate-missing` で `active=false`
3. 必要に応じて `active_only=false` で監査確認

## Exchange Rate Policy

MVP は固定レート運用とする。定義場所は `App/src/dynagent/billing.py` の `EXCHANGE_RATES_TO_USD`。

- 更新頻度: 毎週月曜（JST）または主要価格改定時
- 責任者: Backend oncall
- 監査ログ: PR に以下を必須記載
  - 変更前/変更後レート
  - レートソース（公的/主要金融データ）
  - 反映日時（UTC）
- 定期見直し: 四半期ごとに使用実績と乖離を分析し、年1回は運用方式（固定表/外部連携）を変更するか正式に再評価する

丸めルール:

- 内部計算: `Decimal`
- DB格納: `Numeric(12, 6)` 準拠
- UI表示: デフォルト小数第2位、詳細は第4位まで

## Observability

以下をログベースメトリクスで定義する。

- `usage_limit_reached_total{scope,window}`  
  - source: `UsageLimitExceededError` 発生ログ / 429レスポンス
- `http_429_total{route,scope}`  
  - source: API access log
- `concurrency_limit_reached_total{scope}`  
  - source: chat/session 実行拒否ログ

## Dashboard/Alert Thresholds

- `usage_limit_reached_total`:
  - warning: 15分平均で 5件超
  - critical: 15分平均で 20件超
- `http_429_total`:
  - warning: 全リクエストの 1% 超
  - critical: 全リクエストの 3% 超
- `concurrency_limit_reached_total`:
  - warning: 1時間で 20件超
  - critical: 1時間で 100件超

## Observability Setup Procedure (00822)

初期セットアップ/更新は `Ops` で実行する。

```bash
cd Ops
make setup-usage-observability ENV=dev
make setup-usage-observability ENV=staging NOTIFICATION_CHANNEL="oncall-pager,backend-email"
make setup-usage-observability ENV=prod-a NOTIFICATION_CHANNEL="oncall-pager,backend-email"
make setup-usage-observability ENV=prod-b NOTIFICATION_CHANNEL="oncall-pager,backend-email"
```

- 実体スクリプト: `Ops/scripts/gcp/setup-usage-observability.sh`
- 作成/更新対象:
  - log-based metrics:
    - `usage_limit_reached_total{scope,window}`
    - `http_429_total{route,scope}`
    - `concurrency_limit_reached_total{scope}`
  - dashboard:
    - `DynAgent Usage Limit Observability (<env>)`
  - alert policies:
    - warning/critical を各メトリクスに対して作成

### Event Log Source

以下のアプリログイベントを log-based metric のソースとする。

- `usage_limit_event type=usage_limit ... status=429`
- `usage_limit_event type=concurrency_limit ... status=429`

### Alert Test Procedure

1. `dev` 環境で usage/concurrency 制限に意図的に到達する操作を実行する
2. `http_429_total` / `usage_limit_reached_total` / `concurrency_limit_reached_total` の増分を確認する
3. 一時的に warning 閾値を下げるか、短時間に連続実行して warning 発火を確認する
4. 通知チャネル（oncall/メール）への到達を確認後、閾値を戻す

### Silence Procedure

- 計画メンテナンス時は Alerting の policy を一時 disable または Snooze を設定する
- 自動復旧後は必ず disable/Snooze を解除し、解除時刻を運用ログへ記録する

### False Positive First Triage

1. `http_429_total` の route ラベル上位を確認し、影響APIを特定
2. `scope`（personal/team）別に偏りを確認
3. `usage_limit_reached_total` と `concurrency_limit_reached_total` のどちらが主因か切り分け
4. 直近のプラン変更・上限設定変更・リリース有無を確認
5. 誤検知の場合は検知時刻/原因/再発防止策を記録し、四半期見直し対象に追加

### Notification Routing Matrix

| Alert Policy | Trigger Condition | Intended Channel | Dev Current Channel |
|---|---|---|---|
| `DynAgent usage_limit_reached_total warning (<env>)` | `usage_limit_reached_total > 5` / 15m | oncall + email | email (`00822-dev-email-primary`, `00822-dev-email-secondary`) |
| `DynAgent usage_limit_reached_total critical (<env>)` | `usage_limit_reached_total > 20` / 15m | oncall + email | email (`00822-dev-email-primary`, `00822-dev-email-secondary`) |
| `DynAgent http_429_total warning (<env>)` | `http_429_total / http_requests_total > 1%` | oncall + email | email (`00822-dev-email-primary`, `00822-dev-email-secondary`) |
| `DynAgent http_429_total critical (<env>)` | `http_429_total / http_requests_total > 3%` | oncall + email | email (`00822-dev-email-primary`, `00822-dev-email-secondary`) |
| `DynAgent concurrency_limit_reached_total warning (<env>)` | `concurrency_limit_reached_total > 20` / 1h | oncall + email | email (`00822-dev-email-primary`, `00822-dev-email-secondary`) |
| `DynAgent concurrency_limit_reached_total critical (<env>)` | `concurrency_limit_reached_total > 100` / 1h | oncall + email | email (`00822-dev-email-primary`, `00822-dev-email-secondary`) |

運用ルール:

- warning は一次切り分け開始通知（即時調査）
- critical は優先度を引き上げ、当番対応（oncall）を必須にする
- 本番系（`staging/prod-a/prod-b`）では oncall チャネルを必ず併用する

### Dashboard URL Confirmation

ダッシュボード URL は以下で確認できる。

```bash
gcloud monitoring dashboards list \
  --project <project-id> \
  --format='table(name,displayName)' \
  | rg 'DynAgent Usage Limit Observability \((dev|staging|prod-a|prod-b)\)'
```

- `name` の末尾IDを使って URL を構成できる:
  - `https://console.cloud.google.com/monitoring/dashboards/custom/<dashboard-id>?project=<project-id>`
- 共有先（Slack/Notion/Runbook）へ貼り、`Worklog/verifications/00822_Usage_Limit_Observability_Dashboard_Alerts.md` の `URL をチーム共有済み` を `[x]` に更新する。

## Concurrency Query Performance (00821)

同時実行判定クエリ（`_count_active_user_executions` / `_count_active_team_executions`）は `Worklog/verifications/00821_Concurrency_Limit_Query_Load_Validation.md` で負荷検証済み。

- 検証時の暫定SLO:
  - 判定処理 `p95 < 100ms`
- 2026-02-17 検証結果:
  - 通常時: `p95 10.792ms`
  - 高負荷時: `p95 50.205ms`
  - 制限到達連発時: `p95 40.140ms`

### Monitoring Recommendation

- `POST /api/workers/{worker_id}/execute` の route latency を継続監視
- `pg_stat_statements` で以下2クエリの `mean/p95/calls` を監視
  - user scope count (`sessions.user_id` 条件)
  - team scope count (`projects.team_id` 条件)
- 判定クエリの `p95 > 80ms` が15分継続したら warning
- 判定クエリの `p95 > 100ms` が15分継続したら critical

### Re-validation Triggers

- `execution_records` が `5,000,000` 件を超過
- `concurrency_limit_reached_total` が1時間連続で warning 超過
- チームプラン/同時実行上限ロジックに変更が入ったとき

## Pre-release Checklist (00820)

1. `alembic upgrade head` で `model_pricing_catalog` を適用
2. `make seed-pricing-catalog-dry-run` で差分ゼロを確認
3. `make test-unit` 実行
4. 既存 `Project.settings` 未設定データで `resource_tier=free` が返ることを確認
5. 使用率API
   - `GET /api/users/me/usage?precision=2`
   - `GET /api/users/me/usage?precision=4&detailed=true`
   - `GET /api/teams/{team_id}/usage?precision=4`
6. 使用率詳細API
   - `GET /api/users/me/usage/pricing-catalog`
