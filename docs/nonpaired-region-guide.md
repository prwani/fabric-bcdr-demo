# Non-paired-region guide

Use this flow when the recovery region is **not** the Azure-paired region for the primary Fabric capacity.

## Outcome

Recover supported Fabric items from Git and restore data from a **pre-disaster secondary-region backup**.

## Flow

1. **Prepare the primary environment**
   - Create the primary capacity.
   - Run [step0-primary-setup](../step0-primary-setup/README.md) to create the workspace and sample artifacts.
   - Seed warehouse sample rows with `step0-primary-setup/sql/seed-warehouse.sql`.
   - Connect the workspace to Git or let the bootstrap script do it.
   - Implement scheduled cross-region backups before any disaster occurs.

2. **Provision the DR capacity**
   - Use [step1-provision-dr-capacity](../step1-provision-dr-capacity/README.md) to create the new Fabric capacity in the target region.

3. **Recreate workspaces and supported items**
   - Follow [step2-recreate-workspace-items](../step2-recreate-workspace-items/README.md).
   - Git is still the mechanism for restoring supported item definitions.

4. **Restore data from storage**
   - Follow [step3-copy-data/nonpaired](../step3-copy-data/nonpaired/README.md).
   - Use the repo-owned restore notebook against the storage-based exports captured before the disaster.
   - For warehouse recovery after the storage restore, use `step3-copy-data/nonpaired/scripts/run-toolbox-warehouse-recovery.sh`.

5. **Restore full function**
   - Follow [step4-restore-full-function](../step4-restore-full-function/README.md).

## Critical constraint

Non-paired-region recovery only works if the repo's scheduled backup process has already exported the required data to a secondary region. There is no native OneLake DR replica to fall back to.

## Suggested backup shape

The backup path should capture at least:

- Lakehouse tables and files
- Warehouse data exports or staging copies
- Backup manifests with source workspace, item IDs, backup timestamps, and table/file inventory
- Workspace and DW security artifacts required for replay
