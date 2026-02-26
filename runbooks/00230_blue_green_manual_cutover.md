# 00230 Blue Green Manual Cutover Procedure

## 1. Purpose

`api.<YOUR_DOMAIN>` を `prod-a` / `prod-b` 間で手動切替する標準手順を定義する。

## 2. Inputs

作業前に以下を確定する。

- `ACTIVE_ENV`: 現在の公開系（`prod-a` または `prod-b`）
- `STANDBY_ENV`: 切替先
- `ACTIVE_IP`: 現在 `api.<YOUR_DOMAIN>` が向いているIP
- `STANDBY_IP`: 切替先IP
- 監視ダッシュボードURL
- ロールバック担当者

## 3. Preconditions

- `STANDBY_ENV` の `./health` が連続成功している。
- `api.prod-a.<YOUR_DOMAIN>` または `api.prod-b.<YOUR_DOMAIN>` で主要機能の確認が完了。
- 変更凍結時間帯/作業通知が完了。
- ロールバック手順（Section 7）を事前確認済み。

## 4. Manual Cutover Steps (Cloudflare)

1. Cloudflare Dashboardで `api.<YOUR_DOMAIN>` の `A` レコードを開く。
2. 値を `ACTIVE_IP` から `STANDBY_IP` に変更する。
3. TTLを事前に短縮している場合は、そのまま維持して反映を待つ。
4. `dig api.<YOUR_DOMAIN> +short` で解決先が `STANDBY_IP` になったことを確認する。
5. 反映時刻を運用ログへ記録する。

## 5. Post-Cutover Verification

切替後 15-30分は以下を監視する。

- `/health` 成功率
- 5xx レート
- p95 レイテンシ
- ログイン/主要導線

異常がなければ以下を記録する。

- 切替完了時刻
- 新Active (`prod-a` or `prod-b`)
- 監視結果サマリ

## 6. Abort Criteria

以下のいずれかを満たした場合、即座にロールバックする。

- `api.<YOUR_DOMAIN>` が継続的に不達
- 5xxが閾値を超えて継続
- 主要機能（認証、主要API）が継続失敗

## 7. Rollback Steps

1. Cloudflare `api.<YOUR_DOMAIN>` の `A` レコードを `ACTIVE_IP`（切替前）へ戻す。
2. `dig api.<YOUR_DOMAIN> +short` で旧IPへ戻ったことを確認する。
3. 旧Active系の `/health` と主要機能を確認する。
4. ロールバック時刻・理由・影響範囲を記録する。

## 8. Operation Log Template

```
Date:
Operator:
ACTIVE_ENV(before):
STANDBY_ENV:
ACTIVE_IP(before):
STANDBY_IP:
Cutover Start:
Cutover Complete:
Rollback: yes/no
Issue Summary:
Monitoring Result:
```
