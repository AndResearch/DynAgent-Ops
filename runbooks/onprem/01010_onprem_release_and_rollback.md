# On-Prem Release and Rollback

## Purpose

Define a safe release sequence and rollback criteria for on-prem Kubernetes deployments.

## Release Sequence

1. Prepare immutable image references (explicit tag and digest).
2. Update `values-<env>.yaml` with new image references.
3. Apply Helm upgrade.
4. Observe rollout and run smoke checks.
5. Mark release as completed in your internal change log.

## No-Go Conditions

- New pods fail readiness within expected time.
- Error rate increases materially after rollout.
- Critical smoke checks fail.

## Rollback Sequence

1. Identify previous stable Helm revision.
2. Run Helm rollback.
3. Verify rollout + health + smoke checks.
4. Record rollback reason and follow-up actions.

## Example Commands

```bash
helm history <YOUR_RELEASE_NAME> -n <YOUR_NAMESPACE>
helm rollback <YOUR_RELEASE_NAME> <REVISION> -n <YOUR_NAMESPACE>
kubectl rollout status deploy/<YOUR_API_DEPLOYMENT> -n <YOUR_NAMESPACE>
```

