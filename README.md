# DynAgent Ops (Public)

このリポジトリは、オンプレ配布向けの公開運用テンプレートを管理します。

## Scope

- Kubernetes/Helm のベンダー非依存テンプレート
- プレースホルダ化された設定例
- on-prem 向けデプロイ/ロールバック/運用 runbook
- 公開運用ポリシー

## Repository Role

- Public repository: `Ops`
- Internal repository: `Ops-internal`

`Ops-internal` には、クラウド固有（GKE/Cloudflare）と社内運用情報を保持します。

## Structure

- `helm/dynagent/` : 公開配布用 Helm チャート（on-prem baseline）
- `platform/kubernetes/` : on-prem Kubernetes 基準
- `runbooks/onprem/` : on-prem 運用runbook
- `policies/` : 公開範囲と分離ポリシー
- `scripts/` : 運用補助スクリプト（アプリ本体コードは含めない）

## App/Ops Boundary

- `App` はアプリ本体（実行コード、テスト、Helmチャート）を管理する。
- `Ops` は運用手順・運用ポリシー・運用補助スクリプトを管理する。
- 原則として、運用スクリプトは `App` ではなく `Ops/scripts` に置く。
- ただし、`App` の build/test 実行そのものは `App` 側の標準入口（`make` など）を使う。

詳細は `policies/00181_app_ops_boundary_policy.md` を参照。

## Helm Migration Status

- 現在は段階移行中（非破壊移行）。
- `Ops/helm/dynagent` は公開配布向けの基準チャートとして利用可能。
- `Ops-internal` には cloud運用向け values を含むチャートを保持。
- `App/helm/dynagent` は互換維持のため当面残し、参照切替完了後に削除予定。

## Safety Checks

公開前チェック:

```bash
./scripts/public/check-public-safety.sh
```

または:

```bash
make check-public-safety
```

## Review Gates

- CODEOWNERS: `.github/CODEOWNERS`
- PR template: `.github/pull_request_template.md`
