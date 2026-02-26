# DynAgent Ops (Public)

このリポジトリは、オンプレ配布向けの公開運用テンプレートを管理します。

## Scope

- 配布可能な手順テンプレート
- プレースホルダ化された設定例
- 公開運用ポリシー

## Repository Role

- Public repository: `Ops`
- Internal repository: `Ops-internal`

内部専用の実運用ログ・履歴・環境固有スクリプトは `Ops-internal` で管理します。

## Safety Checks

公開前チェック:

```bash
./scripts/public/check-public-safety.sh
```

または:

```bash
make check-public-safety
```
