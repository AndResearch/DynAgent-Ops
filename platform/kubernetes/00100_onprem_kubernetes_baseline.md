# On-Prem Kubernetes Baseline

## Purpose

Define vendor-neutral baseline requirements for running DynAgent on Kubernetes in on-prem environments.

## Scope

- Kubernetes cluster readiness
- Namespace and RBAC baseline
- Helm deployment baseline
- Operational checks (health, rollout, rollback)

## 1. Cluster Requirements

- Kubernetes version: supported LTS minor version in your organization.
- Ingress controller: any supported controller (NGINX, Traefik, HAProxy, etc.).
- Storage class: default ReadWriteOnce class for stateful components.
- DNS/TLS: organization-managed domain and certificate strategy.

## 2. Namespace and RBAC Baseline

- Create dedicated namespace: `<YOUR_NAMESPACE>`.
- Use least-privilege service accounts for app and worker components.
- Restrict cluster-admin usage to bootstrap and incident recovery only.

## 3. Configuration Model

- Keep environment-specific values in `values-<env>.yaml` files.
- Keep secrets in organization-approved secret management.
- Do not commit real credentials or internal endpoint details.

## 4. Deployment Baseline

```bash
helm upgrade --install <YOUR_RELEASE_NAME> ./helm/dynagent \
  --namespace <YOUR_NAMESPACE> \
  --create-namespace \
  -f values-<env>.yaml
```

## 5. Verification Checklist

- `kubectl get pods -n <YOUR_NAMESPACE>`: all required pods are `Running`.
- `kubectl rollout status deploy/<YOUR_API_DEPLOYMENT> -n <YOUR_NAMESPACE>` succeeds.
- `/health` endpoint returns success through the ingress URL.
- Critical user flow (login + one execution path) succeeds.

## 6. Rollback Baseline

```bash
helm rollback <YOUR_RELEASE_NAME> <REVISION> -n <YOUR_NAMESPACE>
```

After rollback:

- verify rollout status
- verify `/health`
- verify one critical user flow

