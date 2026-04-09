# Step 0 scripts

This folder now contains the primary bootstrap entrypoint for the demo environment.

## Implemented scripts

- `bootstrap-primary-workspace.sh`
  - resolves the Fabric capacity UUID
  - creates or reuses the primary workspace
  - creates a sample lakehouse, warehouse, notebook, data pipeline, and Spark job definition
  - uploads the sample-data notebook
  - optionally runs the notebook
  - optionally connects the workspace to Git and commits the workspace state
- `run-toolbox-primary-capture.sh`
  - verifies the local toolbox fork paths if requested
  - prints the exact `prwani/fabric-toolbox` notebook and script references to run after the primary workspace is ready

## Upstream dependencies

Step 0 still relies on these `fabric-toolbox` assets after the repo-owned bootstrap is complete:

- `accelerators/BCDR/01 - Run In Primary.ipynb`
- `accelerators/BCDR/workspaceutils.ipynb`
- `accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptFabricDWSecurity.sql`
- `accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptWorkspacePermissions.ps1`
