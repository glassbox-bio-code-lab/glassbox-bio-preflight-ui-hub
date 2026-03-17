# Preflight Smoke Test

The old `scripts/smoke_preflight.sh` helper was removed during the Kubernetes
packaging reset. Use the current chart and the built-in API endpoints directly.

## What To Check

- the chart renders
- the app installs
- the `Deployment` becomes ready
- `GET /api/health` returns `{"status":"ok"}`
- `GET /api/config` returns the expected in-cluster config
- `GET /api/modules` exposes the built-in `computational` module entry

## Prerequisites

- `helm`
- `kubectl`
- `curl`

## Render

```bash
helm template glassbox-preflight chart/preflight
```

## Install

```bash
helm upgrade --install glassbox-preflight chart/preflight \
  --namespace glassbox-preflight \
  --create-namespace
```

## Wait For Readiness

```bash
kubectl -n glassbox-preflight rollout status deployment/glassbox-preflight-preflight
```

## Probe The API

In one shell:

```bash
kubectl -n glassbox-preflight port-forward svc/glassbox-preflight-preflight 8080:8080
```

In another shell:

```bash
curl -fsSL http://127.0.0.1:8080/api/health
curl -fsSL http://127.0.0.1:8080/api/config
curl -fsSL http://127.0.0.1:8080/api/modules
```

## Expected Success Criteria

- the service responds on port `8080`
- `/api/health` returns `status=ok`
- `/api/config` reports `inCluster=true`
- `/api/modules` contains the `computational` module
