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

- `platform/kubernetes/` : on-prem Kubernetes 基準
- `runbooks/onprem/` : on-prem 運用runbook
- `policies/` : 公開範囲と分離ポリシー

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
