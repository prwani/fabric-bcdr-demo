# Native vs `fabric-toolbox` vs custom work

| Capability area | Native Fabric | `fabric-toolbox` | This repo |
|-----------------|--------------|------------------|-----------|
| Capacity provisioning | ARM resource provider | — | **Implemented** with Bicep + shell |
| Primary demo environment bootstrap | Fabric REST APIs | — | **Implemented** with workspace bootstrap script, seed notebook, and warehouse SQL |
| Paired-region OneLake replication | **Yes** | Uses replicated data | Documents and explains the recovery path |
| Git-backed item restore | **Yes** | Automates reconnect + sync | Documents the mapping and workflow |
| Workspace recreation | Fabric REST API | BCDR DR notebook | Reference docs and scenario guidance |
| Lakehouse data copy (paired) | OneLake ABFS access | BCDR DR notebook | Reference docs and scenario guidance |
| Warehouse recovery (paired) | Shortcuts + SQL patterns | BCDR + DW recovery scripts | Reference docs and scenario guidance |
| Workspace permissions replay | Fabric REST API primitives | DW backup/replay scripts, BCDR workflow guidance | Validation and operating guidance |
| DW security replay | SQL scripts | DW backup/replay scripts | Validation and operating guidance |
| Notebook / semantic model / report rebinding | Partial APIs and libraries | BCDR DR notebook | Reference docs and validation plan |
| Non-paired-region backup | **No** | Optional inspiration only | **Implemented** with storage-copy backup notebook and manifest |
| Non-paired-region restore | **No** | Optional inspiration only | **Implemented** with manifest-driven restore notebook |
| End-to-end validation | **No** | Partial | **Planned validation assets** |

## Decision rule

This repo follows a simple rule:

- **Use native Fabric first** when the platform already provides the capability.
- **Reference `fabric-toolbox` second** when upstream automation already exists.
- **Write new code only** for the gaps that remain.
