# Glassbox Preflight Certifier User Guide

This guide covers the shipped preflight product surface: validation, canonical
runner launch, add-on launch, pod/log inspection, and output browsing.

## Overview

The app has four tabs:

1. `Preflight`
2. `Run + Logs`
3. `Add-ons`
4. `Outputs`

Preflight remains a control surface over the canonical Glassbox runner and
module stack. It does not fabricate scientific outputs or maintain a parallel
execution model.

## Preflight

### Required Inputs

The current schema requires `sources.json`.

Supporting files such as `portfolio_selected.csv`, `compounds.csv`,
`targets.csv`, `assays.csv`, and `single_target.json` are accepted when
provided and validated against the active schema/example set in:

- `server/schema/current/schema.json`
- `server/schema/current/examples/*`

### Validation Flow

1. Upload input files.
2. Optionally provide input/output/config URI context for provenance.
3. Run validation.
4. Review pass/warn/fail results and remediation.
5. Generate the ready-to-run pack.

## Run + Logs

This tab launches canonical runner Jobs through `POST /api/pipeline/run`.

### Required Fields

- `Namespace`
- `Project ID`

Optional but commonly used:

- `Run ID`
- `Backend API Token`
- `Run Mode`
- `Enable GPU docking path` for deep-mode GPU scheduling

### Runtime Behavior

- Modules come from `GET /api/modules`
- Pod discovery uses `GET /api/k8s/pods`
- Live logs stream from `WS /ws/k8s/logs`
- Outputs refresh from `GET /api/outputs/list`
- Billing readiness checks use `GET /api/billing/status`

### Auth

If `K8S_AUTH_DISABLED=false`, pod/log access requires a token.

- HTTP: `Authorization: Bearer <token>`
- WebSocket: `WS /ws/k8s/logs?...&token=<token>`

Configure tokens with:

- `K8S_API_TOKENS`
- `K8S_API_TOKENS_FILE`
- `K8S_API_TOKEN`

Roles:

- `viewer`: pods and logs
- `operator`: pods, logs, run actions
- `admin`: pods, logs, run actions, secret write

### Billing Readiness

When billing is enabled and the module is billable, launched Jobs attach the
`ubbagent` sidecar and report one usage event per run.

The readiness check confirms:

- `UBBAGENT_ENABLED=true`
- `MARKETPLACE_REPORTING_SECRET` is set and present in the namespace
- `${GBX_APP_FULLNAME}-ubbagent` ConfigMap exists
- `UBBAGENT_IMAGE` is set

## Add-ons

This tab loads add-on metadata from `GET /api/addons`.

Add-ons are namespace-scoped and run against an existing core `runId`. The UI
checks for required core outputs before allowing an add-on launch.

Current behavior:

- install status distinguishes `installed` from `runnable`
- core output readiness is checked via `GET /api/runs/check`
- only runnable add-ons launch through their configured start endpoints
- premium add-ons can surface as `locked` until their namespace install resources exist
- the add-on card shows the concrete install contract so operators can see:
  - expected `ServiceAccount`
  - expected `ConfigMap`
  - runner image source
  - workspace root source
  - resolved runner image when installed
  - runnable and blocked execution modes
- new add-ons can be packaged without preflight code changes when they fit the
  current contract:
  - one-shot Kubernetes `Job`
  - existing `runId`
  - shared input/output roots
  - registry-defined install/readiness contract
  - append-only outputs under a declared prefix

Current packaged add-on:

- `ipfto`
  - ServiceAccount: `gbx-ipfto-runner`
  - ConfigMap: `gbx-ipfto-addon`
  - expected key: `runnerImage`
  - expected workspace key: `projectsDir`
  - execution modes:
    - `phase2a_only`: supported in Kubernetes when the workspace root is configured and requires existing phase-2A patent evidence
    - `full`: intentionally blocked in the current Kubernetes contract until `GBX_IPFTO_PROJECTS_DIR` and additional credential/config wiring are explicitly supported
  - if required IP/FTO evidence is missing, the add-on returns `SKIPPED` with a machine-readable reason instead of fabricating findings
- `cim`
  - ServiceAccount: `gbx-cim-runner`
  - ConfigMap: `gbx-cim-addon`
  - expected key: `runnerImage`
  - execution modes:
    - `airgap`: supported in the current Kubernetes contract and runs customer-hosted follow-up monitoring against an existing core run
    - `gcp_internal`: intentionally blocked until connector-service wiring is added to preflight
    - `open_web`: intentionally blocked until connector-service and egress-policy wiring are added to preflight
  - outputs are written under `followups/<timestamp>/`
  - the preflight UI does not advertise static quick links for CIM yet because the current Sentinel runtime writes timestamped bundles rather than stable top-level files

Generic add-on packaging pattern:

- declare the add-on in `addons.registry`
- keep install resource names in the registry `install` block
- enable and configure it through `addons.installations.<addonId>`
- place static runtime settings under `addons.installations.<addonId>.configData`
- if the runner needs required config values as environment variables, declare
  them in `install.requiredConfig`; preflight injects those values from the
  add-on ConfigMap or process env at runtime

Example:

```yaml
addons:
  registry:
    - id: myaddon
      title: My Add-on
      outputsPrefix: 07_addons/myaddon
      startEndpoint: /api/addons/myaddon/run
      statusEndpoint: /api/addons/myaddon/status
      requireRunId: true
      install:
        serviceAccountName: gbx-myaddon-runner
        configMapName: gbx-myaddon-addon
        runnerImageKey: runnerImage
        readyModes: ["default"]
        requiredConfig:
          - key: datasetRoot
            env: GBX_MYADDON_DATASET_ROOT
            label: dataset root
            modes: ["default"]
  installations:
    myaddon:
      enabled: true
      image:
        repository: us-docker.pkg.dev/example/project/myaddon
        tag: 1.0.0
      configData:
        datasetRoot: /data/reference/myaddon
```

## Outputs

This tab browses artifacts under `GBX_OUTPUT_ROOT/<runId>`.

Available actions:

- list files via `GET /api/outputs/list`
- download individual artifacts via `GET /api/outputs/download`
- download the repro pack via `GET /api/outputs/repro-pack.tgz`

The UI exposes quick links for common artifacts such as:

- safety HTML
- unified outputs JSON
- summary JSON
- wetlab readiness JSON
- seal records

## Dev-Only Administrative Endpoints

The following endpoints are intentionally not the normal product path and are
disabled unless `GBX_DEV_K8S_ADMIN_API=true`:

- `POST /api/k8s/run`
- `POST /api/k8s/secret`

## Kubernetes Deployment Notes

- The active Helm chart lives at `chart/preflight`
- The Marketplace deployer build lives at `deployer/Dockerfile`
- Verification overlay files live under `apptest/deployer` and `apptest/tester`
- The backend uses in-cluster service-account-backed `kubectl` access
- The clean restart currently packages PVC-backed shared storage only
- The app can run standalone or as a sibling deployment that shares namespace,
  storage, runner image, and runner service-account conventions with the
  molecular audit stack

## Troubleshooting

- No pods found: verify namespace, token, and run/job identity
- Logs not streaming: confirm the pod exists and the token has `viewer` access
- Billing not ready: inspect the missing Secret/ConfigMap/env vars shown in the UI
- No outputs listed: confirm the `runId` exists under `GBX_OUTPUT_ROOT`
