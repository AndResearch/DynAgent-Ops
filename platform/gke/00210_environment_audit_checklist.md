# 00210 Environment Audit Checklist

## 1. Purpose

- `dev` / `staging` / `prod-a` / `prod-b` の運用状態を定期監査し、設定ドリフトと運用リスクを早期検知する。
- 2026-02-21 に発生した `SSL_CERTIFICATES` quota 超過（`mcrt-*` 証明書滞留）を再発防止する。

## 2. Audit Scope

- GKE API/Worker cluster status
- Ingress host/IP/certificate binding
- Cloud SQL/Secret Manager 前提の設定整合
- 環境ごとの CORS / domain / image digest 整合
- SSL certificate inventory（固定証明書 + orphan `mcrt-*`）

## 3. Mandatory Checks

1. Cluster Health
- `gcloud container clusters describe <YOUR_API_CLUSTER_NAME> ...` が `RUNNING`。
- 必要時は `<YOUR_WORKER_CLUSTER_NAME>` も `RUNNING`。

2. Ingress and Endpoint Health
- `kubectl get ingress -n dynagent` で期待ホストを公開している。
- `ingress.gcp.kubernetes.io/pre-shared-cert` が環境固定証明書を参照している。
- `networking.gke.io/managed-certificates` を使っていない。

3. Fixed SSL Certificate Policy
- 環境ごとに固定証明書名を使用する。
  - `dev`: `dynagent-api-cert-dev`
  - `staging`: `dynagent-api-cert-staging`
  - `prod-a`: `dynagent-api-cert-prod-a`
  - `prod-b`: `dynagent-api-cert-prod-b`
- 上記証明書の `managed.status` が `ACTIVE`（または新規作成直後は短時間 `PROVISIONING`）。

4. mcrt Residue Check (Important)
- `mcrt-*` 証明書が残っていないことを確認する。
- 残っている場合は「target proxy 未参照（orphan）」のみ削除する。
- 参照中証明書は削除しない。

5. Deploy State Consistency
- `values-cloud-<env>.yaml` の image digest と `releases/deploys/<env>/` 最新記録の一致を確認する。
- `build -> values更新(commit) -> deploy` の順を守る。

## 4. Incident Note (2026-02-21)

- 事象:
  - Frontend login が `Failed to fetch`。
  - Browser console に `POST https://api.dev.<YOUR_DOMAIN>/api/auth/login net::ERR_CONNECTION_RESET`。
- 原因:
  - ManagedCertificate 再作成の繰り返しで `mcrt-*` が増殖し、`SSL_CERTIFICATES` quota 上限（10）を超過。
  - 新規証明書作成が失敗し TLS 終端が不整合となった。
- 対応:
  - 証明書運用を `pre-shared-cert` に固定化。
  - orphan `mcrt-*` を全環境で削除。

## 5. Audit Command

```bash
cd Ops
make audit-ssl ENV=all
```

- orphan `mcrt-*` の削除まで行う場合:

```bash
cd Ops
make audit-ssl-clean ENV=all
```

## 6. Operator Rule

- `audit-ssl` は定期実行（最低: クラスタ起動・停止運用の前後）。
- `audit-ssl-clean` は `mcrt-*` 残留が検出されたときだけ実行する。
- `prod-a` / `prod-b` でも停止/再起動運用を行う場合は、同じ監査を必須にする。
