# `fabric-toolbox` inventory used by this repo

The repo depends on the following upstream assets from [`prwani/fabric-toolbox`](https://github.com/prwani/fabric-toolbox).

## Core BCDR accelerator

| Path | Purpose | Used in this repo |
|------|---------|-------------------|
| `accelerators/BCDR/01 - Run In Primary.ipynb` | Captures source-environment metadata into OneLake for recovery | Step 0 metadata collection |
| `accelerators/BCDR/02 - Run In DR.ipynb` | Recreates workspaces, reconnects Git, restores supported items, and drives DR restore steps | Steps 2-4 paired-region flow |
| `accelerators/BCDR/workspaceutils.ipynb` | Shared utility notebook used by the BCDR notebooks | Step 0 and paired-region recovery flow |
| `accelerators/BCDR/Fabric BCDR Accelerator User Guide.pdf` | Companion guidance for the BCDR notebooks | Operator reference |

## Data warehouse backup and recovery

| Path | Purpose | Used in this repo |
|------|---------|-------------------|
| `accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptFabricDWSecurity.sql` | Scripts current warehouse permissions for later replay | Step 0 backup and Step 4 restore |
| `accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptWorkspacePermissions.ps1` | Scripts workspace permissions for later replay | Step 0 backup and Step 4 restore |
| `accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1` | Alternative PowerShell-driven recreation flow | Step 2 alternative path |
| `accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/IngestDataIntoDeployedWarehouse.sql` | Generates warehouse ingestion commands against a staging lakehouse | Step 3 paired-region warehouse recovery |

## Optional complementary assets

| Path | Purpose | How this repo treats it |
|------|---------|-------------------------|
| `accelerators/mirror-lakehouse/` | Mirrors lakehouse structure with shortcuts and copies SQL analytics endpoint objects | Optional idea for proactive non-paired backup patterns |
| `tools/copy-warehouse/` | Copies a Fabric warehouse to a lakehouse | Optional warehouse-to-lakehouse backup helper |

## Notes

- This repo references the forked toolbox paths directly instead of vendoring the toolbox into this repository.
- The toolbox remains the authoritative source for its notebooks and scripts.
- The BCDR accelerator focuses on backup and recovery orchestration; the sample-data seeding pattern used in this repo comes from `multi-region-nonpaired-enterprise-prototype`, not from `accelerators/BCDR/`.
