# Fabric BCDR Demo

Public demonstration repo for Microsoft Fabric Business Continuity & Disaster Recovery (BCDR) across **paired-region** and **non-paired-region** recovery scenarios.

This repo is intentionally **native-first**:

- Use **Fabric Git integration** to restore supported item definitions.
- Use **OneLake DR replication** where Fabric already provides paired-region recovery.
- Use **fabric-toolbox** accelerators as the main recovery engine instead of rewriting them.
- Add custom assets only where there is a gap: DR capacity provisioning, non-paired backup/restore, validation, and end-to-end demo glue.

See [PLAN.md](PLAN.md) for the full implementation plan that drives this repo.

## Current implementation status

The repo now contains the initial working foundation:

- **Step 0 automation** for building the primary workspace, creating sample artifacts, and seeding primary lakehouse data
- **Step 1 automation** for provisioning a new Microsoft Fabric capacity in the DR region with Bicep + shell.
- **Config schema** and example config to standardize future scripts and notebooks.
- **Docs and step guides** that map native Fabric features, `fabric-toolbox`, and new repo assets.
- **Non-paired backup/restore notebooks** for storage-based recovery flows.
- **Demo entrypoints** for primary setup and DR walkthroughs.

The remaining implementation work is tracked in `PLAN.md`.

## Recovery model

The repo follows the 4-step recovery sequence from Microsoft Learn:

1. **Provision DR capacity**
2. **Recreate workspace and Git-backed items**
3. **Restore data**
4. **Restore full function and validate**

For paired regions, data copy reads from the **OneLake DR replica** after failover using the original ABFS paths. For non-paired regions, data must come from a **pre-disaster cross-region backup**.

## Repository layout

```text
fabric-bcdr-demo/
├── docs/
├── config/
├── step0-primary-setup/
├── step1-provision-dr-capacity/
├── step2-recreate-workspace-items/
├── step3-copy-data/
├── step4-restore-full-function/
├── e2e-demo/
├── ATTRIBUTION.md
├── PLAN.md
└── README.md
```

## Quick start

1. Read [docs/prerequisites.md](docs/prerequisites.md).
2. Copy `config/bcdr-config.example.json` to `config/bcdr-config.json` and tailor it to your tenant.
3. Build the primary demo workspace with [step0-primary-setup](step0-primary-setup/README.md).
4. Provision the DR capacity with [step1-provision-dr-capacity](step1-provision-dr-capacity/README.md).
5. Follow the scenario guide for [paired regions](docs/paired-region-guide.md) or [non-paired regions](docs/nonpaired-region-guide.md).

## Step map

| Step | Repo path | What lives here |
|------|-----------|-----------------|
| Step 0 | [`step0-primary-setup/`](step0-primary-setup/) | Primary-region setup, DR enablement guidance, metadata collection references |
| Step 1 | [`step1-provision-dr-capacity/`](step1-provision-dr-capacity/) | New capacity provisioning assets implemented in this repo |
| Step 2 | [`step2-recreate-workspace-items/`](step2-recreate-workspace-items/) | Git reconnect + item restore references to upstream `fabric-toolbox` |
| Step 3 | [`step3-copy-data/`](step3-copy-data/) | Paired-region copy references + non-paired custom design |
| Step 4 | [`step4-restore-full-function/`](step4-restore-full-function/) | Rebinding, security replay, validation guidance |

## Upstream dependencies

This repo builds on the following upstream `fabric-toolbox` assets:

- `accelerators/BCDR/01 - Run In Primary.ipynb`
- `accelerators/BCDR/02 - Run In DR.ipynb`
- `accelerators/BCDR/workspaceutils.ipynb`
- `accelerators/data-warehouse-backup-and-recovery/...`
- `accelerators/mirror-lakehouse/`
- `tools/copy-warehouse/`

See [docs/fabric-toolbox-inventory.md](docs/fabric-toolbox-inventory.md) and [ATTRIBUTION.md](ATTRIBUTION.md) for the detailed mapping.
