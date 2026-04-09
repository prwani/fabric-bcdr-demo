# Paired-region guide

Use this flow when the primary Fabric capacity has **OneLake DR** enabled and Microsoft fails data access over to the Azure-paired region.

## Outcome

Recover supported Fabric items into a new DR workspace and copy data from the paired-region replica into the new environment.

## Flow

1. **Prepare the primary environment**
   - Create the primary capacity.
   - Run [step0-primary-setup](../step0-primary-setup/README.md) to create the workspace and sample artifacts.
   - Seed warehouse sample rows with `step0-primary-setup/sql/seed-warehouse.sql`.
   - Connect the workspace to Git or let the bootstrap script do it.
   - Enable DR on the capacity.
   - Run the primary metadata capture notebook from `fabric-toolbox`.

2. **Provision the DR capacity**
   - Use [step1-provision-dr-capacity](../step1-provision-dr-capacity/README.md) to create the new Fabric capacity in the DR region.

3. **Recreate workspaces and supported items**
   - Follow [step2-recreate-workspace-items](../step2-recreate-workspace-items/README.md).
   - The main upstream asset is `accelerators/BCDR/02 - Run In DR.ipynb`.

4. **Restore data**
   - Follow [step3-copy-data/paired](../step3-copy-data/paired/README.md).
   - Lakehouse and warehouse data are restored from the paired-region replica after failover.

5. **Restore full function**
   - Follow [step4-restore-full-function](../step4-restore-full-function/README.md).
   - Rebind notebooks, semantic models, reports, pipelines, and replay security where required.

## Important data-copy rule

After OneLake failover, the original ABFS paths point at the **replicated data in the paired region**. The recovery notebook reads from those paths and copies into the newly created DR workspace.

## When this flow does not apply

Do not use this guide for non-paired regions. There is no native cross-region data replica in that scenario.
