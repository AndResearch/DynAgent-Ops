# On-Prem Day-2 Operations Checklist

## Purpose

Provide a periodic operations checklist for stable on-prem Kubernetes operation.

## Daily

- Check workload health (`pods`, `deployments`, restarts)
- Check error logs for API/worker
- Confirm ingress certificate validity window

## Weekly

- Verify backup/restore drill status
- Review capacity (CPU/memory/storage headroom)
- Review security updates for cluster/runtime dependencies

## Before Upgrade

- Freeze change window
- Confirm rollback path
- Confirm monitoring and alerting coverage

## Incident Minimum Record

- detection time
- impact scope
- mitigation performed
- root cause summary
- preventive action

