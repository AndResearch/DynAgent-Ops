# GKE Standard Worker Cluster Provisioning

Request `00810_GKE_Standard_Cluster_Provisioning` の実行手順。

## Scope

- GKE Standard クラスタ `<YOUR_WORKER_CLUSTER_NAME>`
- `worker-pool` ノードプール
- `<YOUR_WORKER_CLUSTER_NAME>` Namespace + `dynagent-worker` KSA
- Workload Identity binding
- Autopilot Pod CIDR -> Worker gRPC (`tcp/50051`) firewall ルール

## Prerequisites

- `gcloud`, `kubectl` が利用可能
- 対象プロジェクトへの権限:
  - GKE cluster / node-pool 作成
  - IAM policy binding
  - Compute firewall-rules 作成
- Autopilot側 Pod CIDR を把握していること

## Execute

`Ops` 配下で実行:

```bash
make provision-worker \
  ENV=dev \
  AUTOPILOT_POD_CIDR=10.20.0.0/14
```

主要オプション:

- `USE_DEDICATED_GSA=1`
  - `dynagent-worker@<YOUR_GSA_DOMAIN>` を作成して利用
  - 未指定時は既存 `dynagent-app@<YOUR_GSA_DOMAIN>` を共有
- `ENABLE_PRIVATE_ENDPOINT=1`
  - GKE private endpoint を有効化
- `MASTER_CIDR=172.16.x.0/28`
  - control plane CIDR を明示上書き

## Notes

- 環境名は `dev|staging|prod-a|prod-b` のみ。`prod` は禁止。
- Blue/Green 運用では `prod-a` / `prod-b` を明示すること。
- `AUTOPILOT_POD_CIDR` が未確定な場合は firewall 設定が正しく作成できない。

## Why Bastion Is Required

Workerクラスタは `ENABLE_PRIVATE_ENDPOINT=1` を前提に運用する。
この設定では、Kubernetes API（control plane endpoint）への到達はVPC内部経路に制限されるため、ローカル端末やCloud Shellからの `kubectl` は到達できない場合がある。

そのため、VPC内部に踏み台VMを配置し、IAP経由で安全に接続して `kubectl` を実行する運用を採用する。

### Security Intent

- control planeを公開インターネットから隔離する（攻撃面の縮小）
- 管理操作の経路を踏み台に集約し、監査/制御をしやすくする
- IAM + IAPを前提としたアクセス統制を維持する

### Operational Behavior

- `start-clusters.sh ... workers|all`
  - 踏み台VM `dynagent-bastion-<env>` を作成
  - 予約内部IP `dynagent-bastion-<env>-ip` を割当
  - 踏み台からWorker endpoint:443到達をチェック
- `stop-clusters.sh ... workers|all`
  - 踏み台VMを削除
  - 予約内部IPも削除

注: 予約内部IPを削除するため、次回ライフサイクルで同一IPになる保証はない。
