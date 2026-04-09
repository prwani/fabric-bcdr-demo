# Step 4: restore full function

Once the new workspace and data are in place, the recovered environment still needs post-restore work to become fully functional.

## Recovery areas

- notebook default lakehouse rebinding
- pipeline source and sink rewiring
- semantic model and report rebinding
- workspace and warehouse security replay
- end-to-end validation

## Upstream anchors

- `fabric-toolbox/accelerators/BCDR/02 - Run In DR.ipynb`
- `fabric-toolbox/accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptFabricDWSecurity.sql`
- `fabric-toolbox/accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptWorkspacePermissions.ps1`

## What this repo adds

- validation CLI, notebook, and warehouse SQL assets
- step-level documentation that ties the different upstream components together

## References

See [reference/README.md](reference/README.md), [dw-security/README.md](dw-security/README.md), and [validation/README.md](validation/README.md).
