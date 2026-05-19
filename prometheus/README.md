# DynAgent Observability — Prometheus (Phase 6 Task 6e)

Phase 6 Task 6e で確定した Prometheus 配線資材。Haskell core の `/metrics` endpoint (Phase 0 Task 0j + Phase 5 Task 5c で expose 済) を scrape する 2 系統:

| 配線パターン | ファイル | 利用条件 |
|---|---|---|
| prometheus-operator (推奨) | dynagent-core Helm chart の [`templates/servicemonitor.yaml`](../../Ops/helm/dynagent-core/templates/servicemonitor.yaml) | クラスタで `prometheus-operator` が稼働 + `serviceMonitor.enabled: true` |
| static scrape config | [`scrape-configs/dynagent-core.yaml`](scrape-configs/dynagent-core.yaml) | prometheus-operator 不使用、standalone Prometheus を `scrape_configs:` で運用 |

## Scrape 対象 metric (Haskell core /metrics)

Phase 5 Task 5c で 10 counter + 1 gauge:

| metric | 種別 | 由来 (Phase) |
|---|---|---|
| `dynagent_health_requests_total` | counter | 0 (smoke) |
| `dynagent_step_requests_total` | counter | 0 (echo) — Phase 2+ で hylo δ |
| `dynagent_betaapo_decide_requests_total` | counter | 1 (β_apo 4 分岐判定) |
| `dynagent_check_invariants_requests_total` | counter | 4 (Trans-N detector advisory) |
| `dynagent_invariant_violations_total` | counter | 4 (Violation emit 数累積) |
| `dynagent_experiment_treatment_assign_requests_total` | counter | 5 (FNV-1a arm 割当) |
| `dynagent_experiment_eta_op_requests_total` | counter | 5 (η^op 計算) |
| `dynagent_experiment_aug_err_sum_requests_total` | counter | 5 (5-項 splice) |
| `dynagent_experiment_xcross_doubly_robust_requests_total` | counter | 5 (IPW component) |
| `dynagent_experiment_sample_size_requests_total` | counter | 5 (命題 19.4.8 N 計算) |
| `dynagent_experiment_eta_op_value` | gauge | 5 (η^op last-call、NaN = undefined) |

## Phase 6 Task 6f 連携

Task 6f (alerting rules) は本ファイルで定義した scrape 対象 metric を消費:

- `η^op < 0.1` → `dynagent_experiment_eta_op_value` ガード
- `invariant_violations rate > X / 5min` → `increase(dynagent_invariant_violations_total[5m])`
- `step request p95 > 5s` → `histogram_quantile(0.95, rate(dynagent_step_duration_seconds_bucket[5m]))` (`step_duration_seconds` は Phase 7 で追加判断、Phase 6 段階では request_total の rate を proxy として運用)

詳細は `Ops/prometheus/rules/dynagent_phase6.yaml` (Task 6f) を参照。
