# Step 3: copy data for paired-region recovery

In the paired-region scenario, data is copied from the **OneLake DR replica** after failover into the newly recreated DR workspace.

## Primary upstream path

- `fabric-toolbox/accelerators/BCDR/02 - Run In DR.ipynb`

That notebook includes the stages that:

- copy lakehouse data from the replicated source
- rebuild warehouse data using staging patterns
- continue into post-copy recovery tasks

## Complementary warehouse options

- `fabric-toolbox/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/IngestDataIntoDeployedWarehouse.sql`
- `fabric-toolbox/tools/copy-warehouse/`

## Important behavior

The source for the copy step is the **replicated data now available in the paired region** through the original ABFS paths. The data is read-only until it is copied into the new workspace.

## References

See [reference/README.md](reference/README.md).
