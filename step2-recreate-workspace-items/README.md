# Step 2: recreate workspaces and supported items

This step is primarily handled by **native Fabric Git integration** orchestrated through upstream `fabric-toolbox` assets.

## Primary upstream path

- `fabric-toolbox/accelerators/BCDR/02 - Run In DR.ipynb`

That notebook is the main paired-region recovery engine for:

- creating new workspaces
- reconnecting workspaces to Git
- syncing supported Fabric items
- continuing the broader DR recovery workflow

## Alternative warehouse-focused path

- `fabric-toolbox/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1`

Use the PowerShell alternative when you want a more explicit DW-oriented recreation flow.

## What this repo adds

- documentation that explains when to use each upstream asset
- a consistent config model for future wrappers
- Step 1 capacity provisioning so the upstream flows have a target capacity to use

## References

See [reference/README.md](reference/README.md).
