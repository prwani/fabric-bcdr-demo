# Attribution

This repository builds on public Microsoft Fabric guidance and open-source accelerators. The repo adds integration, documentation, and missing automation around those assets rather than replacing them.

## Upstream sources

| Source | Usage in this repo |
|--------|--------------------|
| [`prwani/fabric-toolbox`](https://github.com/prwani/fabric-toolbox) | Active toolbox fork referenced by this repo for paired-region BCDR, warehouse recovery, lakehouse mirroring, and warehouse-to-lakehouse copy |
| [Microsoft Learn: Experience-specific guidance](https://learn.microsoft.com/en-us/fabric/security/experience-specific-guidance) | Recovery model, capability boundaries, and manual post-recovery guidance |
| [Microsoft Learn: OneLake disaster recovery](https://learn.microsoft.com/en-us/fabric/onelake/onelake-disaster-recovery) | Paired-region replication and failover concepts |
| [Azure template reference: `Microsoft.Fabric/capacities`](https://learn.microsoft.com/en-us/azure/templates/microsoft.fabric/2023-11-01/capacities) | Source for the Fabric capacity Bicep resource implemented in this repo |
| [`prwani/multi-region-nonpaired-enterprise-prototype`](https://github.com/prwani/multi-region-nonpaired-enterprise-prototype) | Conceptual inspiration for non-paired-region orchestration and multi-region framing |

## Referenced fabric-toolbox assets

- `accelerators/BCDR/01 - Run In Primary.ipynb`
- `accelerators/BCDR/02 - Run In DR.ipynb`
- `accelerators/BCDR/workspaceutils.ipynb`
- `accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptFabricDWSecurity.sql`
- `accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptWorkspacePermissions.ps1`
- `accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1`
- `accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/IngestDataIntoDeployedWarehouse.sql`
- `accelerators/mirror-lakehouse/`
- `tools/copy-warehouse/`

## Additional upstream implementation references

- `multi-region-nonpaired-enterprise-prototype/step1-primary-baseline/scripts/setup-fabric-healthcare.sh`
- `multi-region-nonpaired-enterprise-prototype/step1-primary-baseline/samples/E-fabric-healthcare/cms_healthcare_demo.ipynb`

## Notes

- Upstream notebooks, scripts, and documentation retain their original licenses and ownership.
- This repo references upstream paths directly whenever possible so improvements can continue to flow from the source projects.
