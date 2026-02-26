# Frontend/API 起動パターンメモ

最終更新: 2026-02-12

## 前提

- Frontend は `App/frontend` で `npm run dev` を実行する。
- `VITE_API_URL` 未指定時は相対パス (`/api`, `/ws`) を使う。
- `VITE_API_URL` 指定時は指定先APIに直接アクセスする。

## パターン1: ローカルAPIを使う（通常のローカル開発）

この場合は Backend をローカル起動する必要がある。

```bash
# Terminal A
cd App
make run-api

# Terminal B
cd App/frontend
npm run dev
```

- `vite.config.ts` のプロキシで `http://localhost:8000` に転送される。
- `make run-api` を起動していないと `ECONNREFUSED` が出る。

## パターン2: GKE dev APIを直接使う（Backendローカル起動なし）

この場合は `make run-api` は不要。

```bash
cd App/frontend
VITE_API_URL=https://api.dev.<YOUR_DOMAIN> npm run dev -- --host 127.0.0.1 --port 4173
```

- Frontend は `https://api.dev.<YOUR_DOMAIN>` に直接アクセスする。
- WebSocket も同じベースURLから `wss://.../ws/...` に切り替わる。

## よくあるエラー

### `http proxy error: /api/... ECONNREFUSED`

- 原因: パターン1で `make run-api` が未起動。
- 対処: `cd App && make run-api` を先に実行する。

### `ModuleNotFoundError: No module named 'dynagent'`（`make run-api` 時）

- 原因: `.venv` の editable install が壊れている可能性。
- 対処: `cd App && make bootstrap` を再実行して `.venv` を再構築する。
