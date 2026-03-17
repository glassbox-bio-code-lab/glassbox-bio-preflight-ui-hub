# Public Repo Layout

This document defines the customer-facing repository boundary for the
**Glassbox Bio Preflight UI Hub**.

The public repo should contain only the deployment, packaging, sample, and
documentation surface that customers need to install and operate the product.

It should **not** contain the frontend/backend application implementation that
Glassbox develops privately.

## Include In The Public Repo

These paths are part of the customer-facing distribution set:

- `README.md`
  - use the public template generated from `customer_repo_seed/README.md`
- `chart/preflight/`
  - Helm chart used to deploy the product
- `deployer/`
  - Marketplace deployer image build context
- `apptest/`
  - Marketplace verification/test assets
- `schema.yaml`
  - Marketplace deployer schema
- `metadata.json`
  - product/package metadata
- `docs/`
  - operator documentation and support references
- `sample_input/`
  - example input bundle for validation and smoke workflows

## Exclude From The Public Repo

These paths are internal implementation and should remain private:

- `App.jsx`
- `index.jsx`
- `index.html`
- `components/`
- `server/`
- `services/`
- `utils/`
- `globalStyles.jsx`
- `constants.ts`
- `types.ts`
- `package.json`
- `package-lock.json`
- `vite.config.ts`
- `tailwind.config.js`
- `postcss.config.js`
- `tsconfig.json`
- top-level runtime `Dockerfile`
- `dist/`
- `node_modules/`
- internal screenshots / local review images
- `AGENTS.md`
- `option*.md`

## Why The Split Exists

Customers deploy the published Glassbox runtime image into their own Kubernetes
environment. They do not need the private React/Node source tree in order to
install or use the product.

The public repo is therefore the **deployment contract**, not the full
application development workspace.

## Export Workflow

Use the export script to assemble a clean customer repo seed:

```bash
cd preflight_v2
chmod +x scripts/export_customer_repo.sh
./scripts/export_customer_repo.sh /absolute/path/to/preflight-public-repo
```

The script writes a clean target tree containing only the public-facing files.

## Exported Root Layout

The exported repo root will contain:

- `README.md`
- `chart/preflight/`
- `deployer/`
- `apptest/`
- `docs/`
- `sample_input/`
- `schema.yaml`
- `metadata.json`

## Notes

- The exported repo is the correct starting point for the customer/public repo.
- The working `preflight_v2/` directory remains the private implementation tree.
- If the public docs or chart change, regenerate the public repo using the
  export script instead of copying the whole working directory.
