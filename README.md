# Glassbox Bio Preflight UI Hub

This repository is the customer-facing deployment bundle for the
**Glassbox Bio Preflight UI Hub**.

It packages the Helm chart, operator guide, sample bundle, and Marketplace
support assets used to deploy the published Preflight images into a customer
Kubernetes cluster. It does not contain substitute scientific workflows or
fabricated scientific outputs.

## What Customers Use This Repo For

- install the published Preflight UI with Helm
- validate real customer bundles against the shipped contract
- save certified inputs into cluster-backed storage
- launch and monitor canonical Glassbox runs in Kubernetes
- review certifications, logs, artifacts, and supported add-ons

Preflight is an operator control surface over the canonical Glassbox execution
stack. It does not invent missing scientific evidence, fabricate outputs, or
replace the scientific runner.

## Repo Layout

- `chart/preflight/`
  Customer Helm chart for direct deployment.
- `docs/USER_GUIDE.md`
  Customer operator workflow guide.
- `docs/Glassbox Bio Preflight UI — Architecture Diagram.png`
  Architecture reference image.
- `sample_input/`
  Example bundle structure and reference files.
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

## Deployment Notes

- the chart deploys the published image references already pinned in
  `chart/preflight/values.yaml`
- `service.type` defaults to `ClusterIP` on port `8080`
- auth is enabled by default; `app.authDisabled=true` is only supported for
  trusted internal `ClusterIP` installs
- the shared data contract is PVC-backed under `/data`
- the chart includes a `runtime-tools` init container that stages `kubectl` and
  `helm` into `/tools` because the runtime expects them to be available
- add-ons run only after the core run outputs they depend on are present

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
