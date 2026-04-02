# On-Prem Deployment Runbook

## Purpose

Standard deployment runbook for DynAgent on customer-managed Kubernetes.

## Preconditions

- Cluster access (`kubectl` + namespace permissions)
- Helm chart package available
- Environment values file prepared (`values-<env>.yaml`)
- Secrets provisioned in cluster or external secret provider
- Decide where the package mirror should live for Worker dependency installation
  (`in-cluster`, same private network/VPC, or other internal artifact host)

## Steps

1. Validate namespace and required secrets.
2. Run Helm upgrade/install.
3. Check rollout status for API and worker workloads.
4. Validate ingress reachability and `/health`.
5. Execute one smoke scenario (login + command execution).
6. Record or confirm the package mirror placement plan for Worker dependency distribution.

## Example Commands

```bash
kubectl get ns <YOUR_NAMESPACE>
kubectl get secret -n <YOUR_NAMESPACE>

helm upgrade --install <YOUR_RELEASE_NAME> ./helm/dynagent \
  --namespace <YOUR_NAMESPACE> \
  --create-namespace \
  -f values-<env>.yaml

kubectl rollout status deploy/<YOUR_API_DEPLOYMENT> -n <YOUR_NAMESPACE>
kubectl get pods -n <YOUR_NAMESPACE>
```

## Completion Criteria

- All required workloads are healthy
- `/health` passes from ingress endpoint
- Smoke scenario passes
