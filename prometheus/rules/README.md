# DynAgent Alerting Rules (Phase 6 Task 6f)

Phase 6 Task 6f で確定した Prometheus alerting rules。Phase 5 で expose 済の counter + gauge を消費して、operator が初期段階で発火可能な 5 alert を pin。

## 構成

| ファイル | 用途 |
|---|---|
| [`dynagent_phase6.yaml`](dynagent_phase6.yaml) | **PrometheusRule CRD** (prometheus-operator) |
| [`dynagent_phase6_standalone.yaml`](dynagent_phase6_standalone.yaml) | **standalone Prometheus rule_files** 形式 (同内容、wrapper のみ違う) |

PrometheusRule CRD を使う環境では `dynagent_phase6.yaml` のみで足りる (prometheus-operator が discovery + rule reload を行う)。`release: prometheus` label が付いているのでセレクタ整合済。

## 5 alert カタログ (Phase 6 起点 threshold)

| alert | metric | threshold | severity | 持続 | 根拠 |
|---|---|---|---|---|---|
| `DynAgentEtaOpDegraded` | `dynagent_experiment_eta_op_value` | `< 0.1` | P2 | 10m | 起点 0.1 (Phase 5 base rate 未計測、保守値) |
| `DynAgentInvariantViolationSurge` | `dynagent:invariant_violations:5m` (recorded) | `> 5` (= 1/min) | P1 | 5m | Phase 4 advisory but 急増は data quality signal |
| `DynAgentInvariantViolationDoubled` | 同上 / 24h avg | `> 2× baseline` | P2 | 10m | relative regression (baseline 高い env でも検出) |
| `DynAgentStepRequestRateAnomaly` | `dynagent:step_request_rate:5m` (recorded) | `> 100 RPS` | P3 | 10m | latency p95 proxy (`step_duration_seconds_bucket` は Phase 7 候補) |
| `DynAgentCoreDown` | `absent(dynagent_health_requests_total) or up == 0` | true | P1 | 2m | scrape 不能 = pod 落ち or ServiceMonitor 壊れ |

5 recording rule (`step_request_rate / betaapo_decide_rate / check_invariants_rate / invariant_violations / experiment_total_rate`) で expensive な rate() / increase() を pre-compute。

## Threshold の Phase 6 起点根拠

Phase 5 LLM 実走 base rate (η^op / invariant violation 率 / step latency p95) は **本 task 着地時点で未計測**。本ファイル の threshold は「明らかに異常」レベルでの保守起点で、Phase 7 base rate 観測後に refine する想定:

1. **η^op < 0.1**: Phase 5 Task 5d formula = `R_int.num / Σ error num`。0.1 は「error 数の 1/10 しか recovery していない」状態、明らかに健全でない level
2. **invariant violations > 5/5min**: Phase 4 advisory なので false positive 許容範囲。Phase 5 実走で 1 セッションあたり 0-2 violations なら 1 RPS で max 1/min/replica
3. **step request rate > 100 RPS**: Task 6a bench で kernel 自体は 50ns 以下 + JSON encode 1µs。100 RPS = 1 capability per 10ms、Servant Handler 全体で IO 含めれば飽和近い (LLM cost が支配なら大幅低い値で実 latency 劣化)

## Phase 5 LLM 実走後の refinement plan (Phase 6 Task 6.post)

1. **base rate measurement** — 1 週間 prod-a 環境で `dynagent:*_rate:5m` と `dynagent_experiment_eta_op_value` の `histogram_over_time` を取得
2. **percentile-based threshold** — p95 + 3σ などで rule に注入
3. **C0358 candidate (Phase 4 advisory → production flow swap)** — invariant_violations の abort 件数 base rate が `< 0.1%` of `check_invariants_total` であれば `Stop(InvariantViolated _)` raise に昇格

## Alertmanager routing

[`Ops/alertmanager/dynagent-routes.yaml`](../../alertmanager/dynagent-routes.yaml) が routing template:

- P1 → `dynagent-page` receiver (PagerDuty + Slack)
- P2 → `dynagent-ops` receiver (Slack #dynagent-ops)
- P3 → `dynagent-watch` receiver (Slack #dynagent-watch + email digest)

inhibit rule: `DynAgentCoreDown` が発火している間は同 component の他 alert を抑制 (root cause が 1 つで複数 alert を出さない)。

Receiver の secret (PagerDuty integration_url / Slack webhook) は Ops-internal/alertmanager/ で env 別に埋める想定 (Phase 6 Task 6.post 候補)。

## 検証

```bash
# rule syntax check
promtool check rules Ops/prometheus/rules/dynagent_phase6_standalone.yaml

# PrometheusRule CRD form check (要 kubectl + cluster context)
kubectl apply --dry-run=client -f Ops/prometheus/rules/dynagent_phase6.yaml

# unit test (要 promtool, テストデータ別ファイル)
promtool test rules Ops/prometheus/rules/test/*.yaml
```
