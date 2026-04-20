# Glassbox Bio Preflight UI Hub User Guide

This guide describes the current customer-facing Preflight UI and the supported
operator workflow for preparing, validating, launching, and reviewing real
Glassbox work in Kubernetes.

Preflight is a control surface over the canonical Glassbox execution stack. It
validates real inputs, stages certified bundles, launches canonical runs, and
surfaces artifacts and supported add-ons. It does not invent scientific
evidence or generate substitute inputs when required data is missing.

## Navigation Map

The current UI surface includes:

1. `Home / Launchpad`
2. `Intake Workspace`
3. `Validation Workspace`
4. `Certification Report`
5. `Guide Workspace`
6. `Core Runs Workspace`
7. `Reports Overview`
8. `Reports Diff`
9. `Reports Artifacts`
10. `Add-ons Workspace`
11. `Feedback` and `Bug report`

## Recommended Operator Flow

1. Start on `Home`.
2. Use `Intake` to capture project and operator context.
3. Use `Validation` to certify the real input bundle.
4. Review the `Certification Report` and export the run pack and certificate as
   needed.
5. Save validated inputs to the cluster.
6. Continue to `Core Runs` to launch or attach to the canonical run.
7. Use `Reports` to review saved certifications and output artifacts.
8. Use `Add-ons` only after the required core outputs already exist.

For deployments that enable the `ipfto` module, Preflight remains the operator
control hub. The UI can surface `ipfto` as an optional runtime module and
launch the published worker image without embedding the scientific logic into
the UI package itself.

## Deployment Assumptions

- set `app.authToken` during installation unless you are running a trusted
  internal `ClusterIP` deployment and explicitly set `app.authDisabled=true`
- `app.authDisabled=true` is not supported for externally reachable service
  types
- set `application.enabled=false` if your cluster does not support the
  `app.k8s.io/Application` resource
- the default service type is `ClusterIP` on port `8080`
- the default shared storage contract is PVC-backed under `/data`
- the chart stages `kubectl` and `helm` into `/tools` through the
  `runtime-tools` init container because the runtime expects them to be
  available inside the pod
- deployment-specific settings should be selected with the chart overlays:
  `chart/preflight/values.local.yaml`, `chart/preflight/values.gke-dev.yaml`,
  or `chart/preflight/values.gke-prod.yaml`
- the runtime now exposes `GBX_DEPLOYMENT_ENV`, `GBX_CLUSTER_PROVIDER`, and
  `GBX_RUNTIME_TARGET` so the same source code can distinguish local-cluster
  testing from GKE deployment without forking the application code
- local Kubernetes testing is supported through the repo `Makefile` and
  `local-k8s/README.md`, which build the real Preflight and `ipfto` images and
  install the same customer chart into a `k3d` cluster
- `sample_input/` is a reference bundle layout only; it must not be treated as
  substitute scientific evidence for a real customer run

## Home / Launchpad

The Launchpad is the starting screen. It gives you four task-oriented entry
points instead of forcing a single linear flow:

- `Set up project intake`
- `Skip setup and go to validation`
- `Execute a run`
- `See reports and history`

Use Launchpad when you are beginning a new project, want to skip directly into
validation, need to relaunch a run, or want to inspect previous certifications.

## Intake Workspace

Intake captures program context before validation or execution. It is organized
into five steps:

1. `Target`
2. `Program`
3. `Evidence`
4. `Ops`
5. `Review`

Use Intake to record target identifiers, program framing, evidence notes, and
project context. Intake does not validate files and does not create scientific
content to cover missing evidence.

## Validation Workspace

Validation certifies the exact bundle you plan to execute. The page is a
two-step wizard:

1. `Choose data source`
2. `Provide inputs`

Data source options:

- `Upload Local Data`
- `Use GCS Locations`

When you use GCS locations, the UI still validates the real files you attach
while also recording the real storage URIs and project context for provenance.

Validation accepts the canonical bundle slots. Current expected inputs are:

- required: `sources.json`
- optional: `portfolio_selected.csv`, `compounds.csv`, `targets.csv`,
  `assays.csv`, `single_target.json`, `structures/*`, and `supporting/*`

If a required file is missing or malformed, the correct outcome is an explicit
warning or failure. Validation must not fabricate replacement scientific data.

## Certification Report

The Certification Report appears after validation completes. It summarizes the
bundle status and the next operator actions.

Status outcomes:

- `PASS`: ready for traceable execution
- `WARN`: passed with reviewable warnings
- `FAIL`: critical issues must be fixed before launch

Typical actions from this report include:

- review file-level results and remediation guidance
- download the deterministic run pack
- save validated inputs to the cluster
- download the certification artifact for reviewers
- continue into `Core Runs` once the bundle is ready

## Guide Workspace

The Guide page is the built-in reference for canonical file expectations,
recommended operator flow, and the non-negotiable scientific integrity rule.

Use it when onboarding a new operator, confirming the bundle contents, or
checking the recommended execution sequence.

## Core Runs Workspace

Core Runs launches and monitors canonical Kubernetes runs. The page has two main
layers:

1. module selection
2. run controls and runtime monitoring

Common fields include:

- `Namespace`
- `Project ID`
- `Run ID` when attaching or overriding
- `Backend API Token` when required by your deployment
- `Run Mode`
- module-specific options such as deep-mode GPU execution or data-profile
  choices when exposed by the selected module

Typical actions include `Start Run`, `Attach / Refresh`, pod refresh, log
streaming, and artifact refresh.

## Reports

### Overview

Reports Overview keeps saved certification history and the currently selected run
summary in one place. Recent certifications are stored locally in the browser.

### Diff

Reports Diff compares two saved certifications and highlights coverage changes,
validation entry changes, and the net movement in errors and warnings.

### Artifacts

Reports Artifacts lets you browse and download files for a selected `runId`,
including common quick links and the repro pack.

## Add-ons Workspace

Add-ons attach follow-on modules to an existing core run. Core outputs must be
present first, and only launch-ready add-ons can be started.

The page lets you:

- set the namespace and refresh add-on status
- enter a core `runId`
- check whether prerequisite core outputs are present
- inspect each add-on contract and execution readiness
- launch a supported add-on when it is ready

The current supported `ipfto` customer add-on contract is:

- launch path: `Run IP/FTO`
- endpoint: `/api/addons/ipfto/run`
- supported execution modes:
  - `phase2a_only`
  - `full` when the add-on secret contract provides supported LLM credentials
- required upstream files:
  - `results/combined_unified_computational_outputs.json`
- expected quick links:
  - `reports/ipfto_report.html`
  - `reports/ipfto_findings.json`
  - `reports/ipfto_manifest.json`
  - `raw/ipfto/verification/verification_summary.json`

Blocked or locked add-ons should stay visible with an explicit reason. They must
not fabricate findings to appear runnable.

## Feedback And Bug Reporting

Use the sidebar actions `Feedback` and `Bug report` to submit workflow comments,
product suggestions, or runtime defects. The modal can include current UI,
report, and namespace context when available.

## Troubleshooting

- validation blocked: confirm the required `sources.json` file is present and
  valid
- auth failures: verify the token configured at install time and the token used
  in the UI match your deployment
- empty run or pod state: re-check namespace, project ID, and run ID
- no artifacts found: confirm the selected run wrote outputs under the shared
  output root
- add-on not ready: review the add-on card for missing install resources,
  blocked execution modes, or missing core-output prerequisites

## Operating Rule

All validation, execution, and add-on workflows must stay tied to real provided
inputs and real generated artifacts. If required scientific data or execution
prerequisites are missing, the correct result is an explicit `SKIPPED`,
`FAILED`, blocked, or warning state with a real reason.
