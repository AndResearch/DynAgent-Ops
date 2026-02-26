# Phase 0 Workflow Guide

## 目的

Phase 0 (Foundation) における準備作業を詳細化し、後続フェーズの実行基盤を整える。

## 0.1 成功指標の定義

- MTTR: 平均復旧時間の目標値を設定。
- デプロイ頻度: 週/日単位の目標値を設定。
- バグ再発率: 重要バグの再発許容率を設定。
- コスト上限: 月次/プロジェクト単位の上限を設定。

### 0.1.1 指標フォーマット

```
## Metrics
- MTTR:
- Deploy Frequency:
- Bug Recurrence Rate:
- Cost سق (Monthly/Project):
```

## 0.2 E2E検証シナリオの確定

- 重要ユーザーフローを最小5件列挙。
- 各シナリオは入力/期待出力/成功条件を明記。
- 成果物は `Worklog/verifications/` にガイドとして保存。

### 0.2.1 E2Eガイドフォーマット

```
## Scenario
- Title:
- Preconditions:
- Steps:
- Expected:
- Notes:
```

## 0.3 CI検証の自動化

- E2Eガイドから実行可能な部分をCIに組み込む。
- スモークテストを必須に設定し、失敗時は次工程に進めない。

## 0.4 基盤整備チェックリスト

- 設計/仕様/リクエストテンプレの整合確認
- テスト基盤 (pytest, fixtures, timeouts) の整備
- 依存管理 (pyproject, lock) の固定化
- バージョニング/リリース運用方針の確認
