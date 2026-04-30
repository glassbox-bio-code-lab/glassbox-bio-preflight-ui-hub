# Local Kubernetes Workflow

This workflow is for local integration testing of the same Helm chart contract
used in GKE. It builds real Preflight and IP/FTO images from local source
checkouts, imports them into a local `k3d` cluster, and installs the customer
chart with local values.

The workflow does not create substitute scientific inputs or run paid
Marketplace module jobs by itself.

## Requirements

- Docker
- `k3d`
- `kubectl`
- Helm
- a local Preflight source checkout
- a local IP/FTO source checkout when building the optional IP/FTO image

## Required Source Paths

The repo intentionally does not hardcode local workstation paths. Pass the
source locations explicitly:

```bash
export PREFLIGHT_SOURCE_DIR=/absolute/path/to/preflight_v2
export IPFTO_SOURCE_ROOT=/absolute/path/to/repo-containing-ipfto_module
```

## Install Locally

```bash
make dev-k8s-install \
  PREFLIGHT_SOURCE_DIR="${PREFLIGHT_SOURCE_DIR}" \
  IPFTO_SOURCE_ROOT="${IPFTO_SOURCE_ROOT}"
```

This uses:

- `chart/preflight/values.local.yaml`
- `examples/addons/ipfto-values.yaml`
- local image tags `glassbox-local/preflight:dev` and `glassbox-local/ipfto:dev`

## Access The UI

```bash
make dev-k8s-port-forward
```

Then open:

```text
http://127.0.0.1:8080/
```

## Useful Commands

```bash
make dev-k8s-status
make dev-k8s-logs
make dev-k8s-uninstall
make dev-k8s-down
```
