# Customer Deploy Bundle

This directory is the customer-facing deployment package for Glassbox Preflight.

It is intended for the public repo where customer operators will:

- pull the public preflight image from Artifact Registry
- install the Helm chart into their own cluster
- provide their own ingress, storage, and auth values

## Layout

- `helm/glassbox-preflight/`: customer Helm chart
- `examples/customer-values.yaml`: starter values overlay

## Public Image

Default chart image:

- `us-docker.pkg.dev/glassbox-bio-public/glassbox-bio-preflight-ui-hub/glassbox-preflight:`

This public image does not bake `kubectl` or `helm` into the container image.
The customer chart downloads runtime tools into a shared volume at pod startup
through the `runtimeTools` init container.

## Install

```bash
helm upgrade --install glassbox-preflight \
  ./helm/glassbox-preflight \
  --namespace glassbox-preflight \
  --create-namespace \
  -f ./examples/customer-values.yaml
```

## Customer Inputs

Customers should review and override:

- `image.tag` or `image.digest`
- `auth.tokensJson` or `auth.existingSecret`
- `ingress.*`
- `storage.*`
- `app.publicAppUrl`
- `app.publicApiUrl`
- `app.entitlementUrl`
- `app.entitlementAuthMode`
- `app.runnerImage`
- `app.runnerServiceAccount`

## Notes

- `application.enabled=false` by default because customer clusters should not
  need the Kubernetes `Application` CRD.
- `addons.ipfto.enabled=false` by default in the customer package.
- Billing remains disabled by default.
