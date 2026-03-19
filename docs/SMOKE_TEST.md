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

Choose an operator token and pass it at install time. The chart defaults to
API-token auth enabled.

```bash
export GBX_PREFLIGHT_TOKEN="change-me-before-real-use"

helm upgrade --install glassbox-preflight chart/preflight \
  --namespace glassbox-preflight \
  --create-namespace \
  --set app.authToken="$GBX_PREFLIGHT_TOKEN"
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
curl -fsSL -H "Authorization: Bearer $GBX_PREFLIGHT_TOKEN" \
  "http://127.0.0.1:8080/api/runs/check?runId=smoke-test"
```

## Verify The Shipped Core Runner Image

Launch a lightweight smoke Job that proves the configured runner image can pull
and resolve `python3 -m app.gbx_core_runner_v3` without starting a scientific
run.

```bash
curl -fsSL -X POST \
  -H "Authorization: Bearer $GBX_PREFLIGHT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"namespace":"glassbox-preflight"}' \
  "http://127.0.0.1:8080/api/modules/computational/smoke"

curl -fsSL -H "Authorization: Bearer $GBX_PREFLIGHT_TOKEN" \
  "http://127.0.0.1:8080/api/modules/computational/status?namespace=glassbox-preflight"
```

Look for:

- `runnerImage` matching the shipped core runtime image
- `execution.state = "verified"` after the smoke job completes
- `execution.lastSuccessfulJob.name` populated

## Expected Success Criteria

- the service responds on port `8080`
- `/api/health` returns `status=ok`
- `/api/config` reports `inCluster=true`
- `/api/modules` contains the `computational` module
- the authenticated `/api/runs/check` request returns `status=ok`
- the computational smoke endpoint creates a job successfully
- `/api/modules/computational/status` eventually reports `execution.state=verified`
