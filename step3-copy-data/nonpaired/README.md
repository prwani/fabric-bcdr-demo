# Step 3: non-paired-region backup and restore

This folder now contains the repo-owned notebooks for the recovery path Fabric does **not** provide natively.

## Implemented notebooks

- `scheduled-backup.ipynb`
  - copies lakehouse Tables and Files from OneLake to secondary-region storage
  - writes `backup-manifest.json` with the source identifiers and copied paths
- `restore-from-storage.ipynb`
  - reads `backup-manifest.json`
  - restores the backed-up lakehouse content into the recovered DR workspace

## Design goals

- Preserve enough metadata to reconstruct table and file inventory
- Keep backup artifacts in a region independent from the source Fabric region
- Produce deterministic manifests that make restore runs traceable
- Reuse OneLake copy patterns that align with the paired-region recovery flow

## Current warehouse handling

The non-paired notebooks handle the **lakehouse backup/restore path** directly. For warehouse recovery, use `scripts/run-toolbox-warehouse-recovery.sh` to reference the forked toolbox recovery helpers after the storage-backed export has been restored into a staging lakehouse.

## Expected backup contract

The scheduled backup notebook emits:

- backup timestamp
- source workspace and lakehouse identifiers
- backup root URI
- entry-level source and target paths
- a restore manifest that the restore notebook can replay
