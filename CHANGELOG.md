# Changelog

## 2026-04-17

- Added environment-aware Helm contract fields for `app.deploymentEnv`, `app.clusterProvider`, and `app.runtimeTarget`, and surfaced them into the Preflight runtime `ConfigMap`.
- Added `chart/preflight/values.local.yaml` for local-cluster testing against locally built images and the same Kubernetes chart contract used in customer deployments.
- Added `chart/preflight/values.gke-dev.yaml` and `chart/preflight/values.gke-prod.yaml` so the customer repo can switch environments by Helm values instead of changing source code.
- Kept the existing `ipfto` add-on contract intact while making image selection environment-specific through values overlays.
- Trimmed the generic `examples/preflight-values.ipfto.yaml` overlay so it only enables the add-on and no longer overrides environment-specific image selection.
- Added a repo-level `Makefile` and `local-k8s/README.md` for local `k3d` build, image import, Helm install, log inspection, and teardown using the same customer chart contract.
- Switched the local overlay to cluster-imported image names (`glassbox-local/*`) so local Kubernetes testing does not depend on a separate registry bootstrap step.
