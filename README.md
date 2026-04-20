# Glassbox Bio Preflight UI Hub

This repository is the customer-facing deployment bundle for the
**Glassbox Bio Preflight UI Hub**.

It packages the Helm chart, operator guide, sample bundle, and Marketplace
support assets used to deploy the published Preflight images into a customer
Kubernetes cluster. It does not contain substitute scientific workflows or
fabricated scientific outputs.

This repo is also the customer integration point for optional runtime modules
that the published Preflight UI can surface and launch, including the `ipfto`
worker image.

## What Customers Use This Repo For

- install the published Preflight UI with Helm
- validate real customer bundles against the shipped contract
- save certified inputs into cluster-backed storage
- launch and monitor canonical Glassbox runs in Kubernetes
- review certifications, logs, artifacts, and supported add-ons
- enable optional module integrations such as `ipfto` from the same deployment
  bundle

Preflight is an operator control surface over the canonical Glassbox execution
stack. It does not invent missing scientific evidence, fabricate outputs, or
replace the scientific runner.

## Repo Layout

- `chart/preflight/`
  Customer Helm chart for direct deployment.
- `docs/USER_GUIDE.md`
  Customer operator workflow guide.
- `CHANGELOG.md`
  Customer-facing deployment change notes.
- `docs/Glassbox Bio Preflight UI — Architecture Diagram.png`
  Architecture reference image.
- `sample_input/`
  Example bundle structure and reference files.
- `examples/preflight-values.ipfto.yaml`
  Example Helm overlay that enables the `ipfto` add-on resources.
- `chart/preflight/values.local.yaml`
  Local Kubernetes overlay for Docker, `kind`, `k3d`, or Docker Desktop testing.
- `chart/preflight/values.gke-dev.yaml`
  GKE development overlay for registry and environment selection.
- `chart/preflight/values.gke-prod.yaml`
  GKE production overlay for registry and environment selection.
- `Makefile`, `local-k8s/README.md`
  Local `k3d` build, load, install, and debugging workflow for the same customer
  chart contract used in GKE.
- `apptest/`, `deployer/`, `schema.yaml`, `metadata.json`
  Marketplace packaging and verification assets. They are included in this repo
  but are not required for a standard Helm install.

## Quick Start

1. Review `docs/USER_GUIDE.md` before installation.
2. Choose a real operator token and set `app.authToken`.
3. If you are installing outside Marketplace or AppRegistry and your cluster
   does not support the `app.k8s.io/Application` CRD, set
   `application.enabled=false`.
4. Install the chart.

```bash
helm upgrade --install glassbox-preflight ./chart/preflight \
  --namespace glassbox-preflight \
  --create-namespace \
  --set app.authToken=REPLACE_WITH_REAL_TOKEN \
  --set application.enabled=false
```

## Environment Overlays

The chart now supports a single runtime contract with environment-specific Helm
overlays instead of source-level forks.

- `chart/preflight/values.local.yaml`
  Use for local Kubernetes integration testing with locally built images loaded
  into a local registry.
- `chart/preflight/values.gke-dev.yaml`
  Use for shared GKE development environments.
- `chart/preflight/values.gke-prod.yaml`
  Use for production GKE deployments.

The runtime receives the deployment metadata through:

- `GBX_DEPLOYMENT_ENV`
- `GBX_CLUSTER_PROVIDER`
- `GBX_RUNTIME_TARGET`

Example local install:

```bash
helm upgrade --install glassbox-preflight ./chart/preflight \
  --namespace glassbox-preflight \
  --create-namespace \
  -f ./chart/preflight/values.local.yaml \
  -f ./examples/preflight-values.ipfto.yaml \
  --set app.authToken=REPLACE_WITH_REAL_TOKEN
```

Example GKE production install:

```bash
helm upgrade --install glassbox-preflight ./chart/preflight \
  --namespace glassbox-preflight \
  --create-namespace \
  -f ./chart/preflight/values.gke-prod.yaml \
  -f ./examples/preflight-values.ipfto.yaml \
  --set app.authToken=REPLACE_WITH_REAL_TOKEN
```

## Local Kubernetes Workflow

The repo now includes a local `k3d` workflow so you can exercise the same
customer chart contract without pushing every iteration to GKE.

```bash
make dev-k8s-install
make dev-k8s-port-forward
```

That workflow builds the real hosted Preflight image, builds the real `ipfto`
worker image, imports both into a local `k3d` cluster, and installs this chart
with `chart/preflight/values.local.yaml` plus
`examples/preflight-values.ipfto.yaml`.

See [local-k8s/README.md](/home/weslinux/Desktop/glassbox-bio-preflight-ui-hub/local-k8s/README.md)
for the full target list.

## Deployment Notes

- the chart deploys the published image references already pinned in
  `chart/preflight/values.yaml`
- `service.type` defaults to `ClusterIP` on port `8080`
- auth is enabled by default; `app.authDisabled=true` is only supported for
  trusted internal `ClusterIP` installs
- the shared data contract is PVC-backed under `/data`
- the chart includes a `runtime-tools` init container that stages `kubectl` and
  `helm` into `/tools` because the runtime expects them to be available
- environment-specific image refs should be selected with the provided values
  overlays; use local tags for local clusters and Artifact Registry tags or
  digests for GKE
- add-ons run only after the core run outputs they depend on are present
- the `ipfto` integration is configured here, but the scientific execution stays
  in the separate published `ipfto` worker image

## IP/FTO Add-On

This repo is the only customer deployment integration point required for the
`ipfto` module. The Helm chart includes the registry entry and install-time
resources that let the published Preflight runtime expose the module in the UI
and launch the worker image.

To enable it, install with an overlay such as
`examples/preflight-values.ipfto.yaml`. That overlay:

- enables the `ipfto` add-on resources
- points Preflight at the published `ipfto` runner image
- provides the shared input, output, and projects paths consumed by the worker

The current hosted runtime supports two `ipfto` execution modes:

- `phase2a_only` for deterministic patent evidence search plus claim similarity
- `full` for the same deterministic patent corpus plus LLM reasoning, gated by
  add-on secrets that provide supported model credentials

If required upstream files or mode-specific secrets are missing, the module must
remain blocked or fail with an explicit reason rather than inventing substitute
scientific evidence.

## Support

When opening a support request, include:

- product version
- namespace
- project ID
- run ID if one exists
- exact error text
- relevant pod or job logs

## Provenance And Integrity

Preflight validates and orchestrates real uploaded inputs. If required inputs or
evidence are missing, the correct outcome is an explicit failure or skip state,
not fabricated substitute data.
