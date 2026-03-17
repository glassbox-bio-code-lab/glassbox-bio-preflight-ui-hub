# Glassbox Bio Preflight UI Hub

This repository is the customer-facing deployment bundle for the
**Glassbox Bio Preflight UI Hub**.

It contains the packaging, configuration, documentation, and sample assets
required to deploy and operate the product in Kubernetes. It intentionally does
not contain the private frontend/backend application source used by Glassbox for
ongoing product development.

## What This Repo Includes

- `chart/preflight/`
  - Helm chart for deployment
- `deployer/`
  - Marketplace deployer build context
- `apptest/`
  - Marketplace verification/test assets
- `schema.yaml`
  - Marketplace deployer schema
- `docs/`
  - operator documentation and support references
- `sample_input/`
  - example validation bundle
- `metadata.json`
  - package metadata

## Product Scope

Glassbox Bio Preflight UI Hub is the operator-facing control surface for
preparing and managing Glassbox Molecular Audit runs in Kubernetes.

It validates real uploaded inputs against the active schema, generates a
deterministic ready-to-run pack, launches the canonical audit runner, streams
live Kubernetes logs, and allows operators to browse and download produced
artifacts from shared storage. It can also launch registry-defined post-core
add-ons against an existing run ID.

The product is a run-control and certification interface over the Glassbox
execution stack. It does not replace the canonical scientific runner and does
not fabricate scientific outputs.

## Start Here

- operator guide: `docs/USER_GUIDE.md`
- smoke test: `docs/SMOKE_TEST.md`
- product description seed: `docs/marketplace_description.md`
- product/package specs: `docs/specs.md`

## Deployment Notes

- customers deploy the published Glassbox runtime image into their own cluster
- this repo provides the deployment and operator contract for that image
- deployment uses the Helm chart under `chart/preflight/`
- Marketplace packaging uses `deployer/`, `apptest/`, and `schema.yaml`

## Support

Use the product documentation for installation, validation workflow, runtime
launch, output browsing, and packaged add-on setup. When opening a support
request, include:

- product version
- namespace
- run ID
- error message
- relevant pod / job logs

## Provenance And Integrity

Glassbox Bio Preflight UI Hub validates and orchestrates real uploaded inputs.
It must not fabricate scientific evidence or substitute synthetic data for
missing required inputs.
