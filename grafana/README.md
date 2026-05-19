# DynAgent Observability — Grafana (Phase 6 Task 6e)

Phase 6 Task 6e で確定した「Grafana dashboard + Prometheus 配線」資材。Phase 5 で expose 済の Prometheus metrics (Haskell core) + App FastAPI dashboard route (5 件) を 1 dashboard で可視化する。

## 構成

```
Ops/grafana/
├── dashboards/
│   └── dynagent_phase6.json     ← 主 dashboard (14 panels)
├── provisioning/
│   ├── datasources.yaml         ← Prometheus + marcusolsson-json-datasource
│   └── dashboards.yaml          ← file-provider が dashboards/ を auto-import
└── README.md                    ← 本ファイル

Ops/prometheus/
└── scrape-configs/
    └── dynagent-core.yaml       ← prometheus-operator なし版 static scrape
```

`Ops-internal/grafana/` と `Ops-internal/prometheus/` は env 別 (dev/staging/prod-a/prod-b) datasource URL / scrape interval を override する想定 (Phase 6 Task 6e 時点では空 dir、Task 6.post 時に Ops 側の正本を copy + URL 差替えで埋める)。

## Dashboard 構成 (`dynagent_phase6.json`)

C0354 layout (E_rep → E_ver → E_dec → R_int) を baseline、Phase 5 で追加した 3 項 (eHist, η^op, X^DR) + Phase 4 invariant-violations + Phase 5 Haskell core request rate を追加した **Phase 6 完成版**:

| panel id | type | title | source |
|---|---|---|---|
| 1 (row) | — | C0354 4-term ratio | — |
| 10 | stat | E_rep ratio | App JSON `aug-err-sum.eRep.ratio` |
| 11 | stat | E_ver ratio | App JSON `aug-err-sum.eVer.ratio` |
| 12 | stat | E_dec ratio | App JSON `aug-err-sum.eDec.ratio` |
| 13 | stat | R_int ratio | App JSON `aug-err-sum.rInt.ratio` |
| 2 (row) | — | Phase 5 additions | — |
| 20 | stat | E_hist ratio | App JSON `aug-err-sum.eHist.ratio` |
| 21 | stat | η^op (Python aggregate) | App JSON `eta-op.value` |
| 22 | timeseries | η^op (Haskell last-call) | Prometheus `dynagent_experiment_eta_op_value` |
| 23 | stat | X^DR last contrast (AIPW) | App JSON `xcross-doubly-robust.point_estimate` (POST) |
| 3 (row) | — | invariant + Haskell counters | — |
| 30 | barchart | Invariant triage breakdown | App JSON `invariant-violations.triage_counts` |
| 31 | timeseries | Haskell core request rate (5min) | Prometheus `rate(dynagent_*_requests_total[5m])` × 8 endpoint |
| 40 | timeseries | Invariant violations emitted (5min) | Prometheus `increase(dynagent_invariant_violations_total[5m])` |

Phase 6 Task 6g 完了後、`rVis` panel を `id=24` で row #2 末尾に追加 (= C0354 layout + Phase 5 + Phase 6g の **6-項 = 完成版**)。

## Datasource 必須要件

1. **Prometheus** — Haskell core `/metrics` を scrape できる Prometheus instance (in-cluster service URL `prometheus.observability.svc.cluster.local:9090` を仮定)。クラスタが prometheus-operator を運用していれば dynagent-core Helm chart `templates/servicemonitor.yaml` が自動 discover、無ければ `Ops/prometheus/scrape-configs/dynagent-core.yaml` を Prometheus の `scrape_configs:` に include。
2. **marcusolsson-json-datasource** — Grafana plugin。インストール:
   ```bash
   grafana-cli plugins install marcusolsson-json-datasource
   ```
   または Helm chart の `grafana.plugins` value で declarative install。

## インストール手順 (Helm 経由想定)

```bash
# 1) prometheus-community/kube-prometheus-stack に dashboards/ + provisioning/ を ConfigMap 経由 mount
kubectl create configmap dynagent-phase6-dashboards \
  --from-file=Ops/grafana/dashboards/ -n observability
kubectl create configmap dynagent-phase6-provisioning \
  --from-file=Ops/grafana/provisioning/ -n observability

# 2) Grafana Helm values で sidecar を有効化 + ConfigMap discovery label を付与
# values:
#   grafana:
#     sidecar:
#       dashboards: { enabled: true, label: grafana_dashboard, labelValue: "1" }
#       datasources: { enabled: true }
#     plugins: [ marcusolsson-json-datasource ]

# 3) DataSource auth 設定 — App FastAPI 側 dashboard route は JWT auth が必要.
#    dashboard service account の JWT を secret に保存 + provisioning/datasources.yaml の
#    secureJsonData.httpHeaderValue1 に "Bearer <token>" を埋める.
```

## Prometheus pip 依存判断 (C0354 / C0357 §未決事項 → Phase 6 Task 6e 着地)

**判断: App 全体への `prometheus-client` pip 依存追加は不要 (Phase 6 では adopt しない)。**

理由:
- App の "active dashboard metric" は全て DB aggregation (`decision_trace_logs` 集計) 経由で計算済。Prometheus expose を重複追加しても本 dashboard が読む surface (App JSON) は変わらない
- App-side で本来 Prometheus 化したい "request counter" は Haskell core が既に expose 済 (Phase 0 Task 0j + Phase 5 Task 5c)
- 将来 (Phase 7+) で App-side に operational counter (DB query latency, external API call duration 等) を追加する要件が出た時点で再評価

C0354 §未決事項 (a)(b)(c) はすべて Phase 6 Task 6e で「不要 / Haskell core が代行 / JSON datasource で代替」として **closed**。

## 検証

```bash
# JSON validate
/Users/shinyakoda/Work/Dynagent/App/.venv/bin/python -c \
  "import json; json.load(open('Ops/grafana/dashboards/dynagent_phase6.json'))"

# Grafana dry-run (要 Docker)
docker run --rm -v $(pwd)/Ops/grafana/dashboards:/etc/grafana/dashboards \
  grafana/grafana:latest grafana-cli admin reset-admin-password 2>&1 | head -3
```
