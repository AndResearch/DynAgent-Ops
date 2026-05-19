# dynagent-core Helm chart (Phase 6 Task 6d, public baseline)

DynAgent v2 Haskell core を Kubernetes クラスタに部署するための、vendor-neutral / on-prem-friendly な Helm chart の公開基盤。GCP 固有の override (Workload Identity, Cloud SQL Proxy 等) は `DynAgent/Ops-internal/helm/dynagent-core/` 側 values-cloud-*.yaml にある。

Phase 6 Task 6c で構築した distroless 化 image (`gcr.io/distroless/cc-debian12:nonroot` ベース、約 23 MB 圧縮) を pull する想定。

詳細な knob 説明は `DynAgent/Ops-internal/helm/dynagent-core/README.md` を参照。

## クイック検証

```bash
# Lint
helm lint ./helm/dynagent-core

# On-prem 用 render
helm template dynagent-core ./helm/dynagent-core \
  --values ./helm/dynagent-core/values-onprem.yaml | less
```

## ファイル構成

| ファイル | 内容 |
|---|---|
| `Chart.yaml` | chart メタ (name, version, appVersion) |
| `values.yaml` | baseline default (autoscaling off, replicaCount=2) |
| `values-onprem.yaml` | on-prem override (replicaCount=1) |
| `templates/_helpers.tpl` | name/label/imageRef helper |
| `templates/deployment.yaml` | Deployment (distroless nonroot + readOnlyRootFilesystem + emptyDir /tmp) |
| `templates/service.yaml` | Service ClusterIP (port 8080) |
| `templates/hpa.yaml` | HPA (autoscaling.enabled の時のみ) |
| `templates/pdb.yaml` | PodDisruptionBudget (pdb.enabled の時のみ) |
| `templates/configmap.yaml` | DYNAGENT_CORE_PORT / GHCRTS / OTEL_EXPORTER_OTLP_ENDPOINT |
| `templates/serviceaccount.yaml` | ServiceAccount (Workload Identity annotation 受け口) |
| `templates/servicemonitor.yaml` | Prometheus Operator ServiceMonitor (serviceMonitor.enabled の時のみ) |
