#!/usr/bin/env bash
set -euo pipefail

# Guard script for public Ops repository.
# - Denies internal-only directories
# - Denies concrete internal identifier patterns in public content

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

readonly DENY_DIRS=(
  "archives"
  "releases"
  "scripts/gcp"
)

readonly SCAN_TARGETS=(
  "README.md"
  "SECURITY.md"
  "Makefile"
  "policies"
  "runbooks"
  "platform"
  "helm"
  ".github/workflows"
)

readonly DENY_PATTERNS=(
  "dynagent-dev"
  "dynagent-staging"
  "dynagent-prod-a"
  "dynagent-prod-b"
  "api\\.dev\\.dynagent\\.work"
  "api\\.staging\\.dynagent\\.work"
  "api\\.prod-a\\.dynagent\\.work"
  "api\\.prod-b\\.dynagent\\.work"
  "api\\.dynagent\\.work"
  "dynagent-[a-z0-9-]+@[^[:space:]]*iam\\.gserviceaccount\\.com"
  "asia-northeast1-docker\\.pkg\\.dev/dynagent-"
  "/Users/"
)

failures=0

echo "[check-public-safety] root=$ROOT_DIR"

for dir in "${DENY_DIRS[@]}"; do
  if [[ -e "$dir" ]]; then
    echo "ERROR: internal-only path exists in public repo: $dir"
    failures=$((failures + 1))
  fi
done

files=()
while IFS= read -r file; do
  files+=("$file")
done < <(
  for target in "${SCAN_TARGETS[@]}"; do
    [[ -e "$target" ]] || continue
    if [[ -d "$target" ]]; then
      find "$target" -type f
    else
      echo "$target"
    fi
  done | sort -u
)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "ERROR: no scan targets found. repository layout may be unexpected."
  exit 1
fi

for pattern in "${DENY_PATTERNS[@]}"; do
  if rg -n --pcre2 "$pattern" "${files[@]}" >/tmp/check-public-safety-hits.$$ 2>/dev/null; then
    echo "ERROR: deny pattern detected: $pattern"
    sed -n '1,20p' "/tmp/check-public-safety-hits.$$"
    failures=$((failures + 1))
  fi
  rm -f "/tmp/check-public-safety-hits.$$"
done

if [[ "$failures" -gt 0 ]]; then
  echo "[check-public-safety] failed: $failures issue(s)"
  exit 1
fi

echo "[check-public-safety] passed"
