# Fabric BCDR Demonstration Repo — Implementation Plan

## Problem Statement

Build a **public demonstration repo** for Microsoft Fabric Business Continuity & Disaster Recovery (BCDR) that covers **both paired-region and non-paired-region** scenarios, organized around the 4-step general recovery plan from Microsoft Learn.

### Design Philosophy
- **Native-first**: Maximize use of Fabric Git integration, OneLake DR replication, REST APIs, and platform features.
- **Reuse-first**: Adopt and improve existing accelerators from `prwani/fabric-toolbox` rather than building from scratch.
- **Additive only**: Write custom code ONLY where native + existing accelerators have gaps.

---

## Research Findings

### Q1: Does Fabric support recovery in a paired region?
**Yes — natively.** When DR is enabled at the capacity level (Admin Portal), OneLake data is asynchronously replicated to the Azure-paired region. In a disaster, data becomes read-only in the secondary; customer must manually provision capacity/workspaces and restore items.

### Q2: Does Fabric support recovery in a non-paired region?
**No native support.** Zone redundancy within a region is available, but cross-region replication to a non-paired region must be fully custom — periodic data export, manual artifact backup, and scripted orchestration.

### Q3: Existing public repos / documented steps?

#### fabric-toolbox Full Inventory (BCDR-relevant)

The `prwani/fabric-toolbox` repo contains **multiple accelerators and tools** relevant to BCDR — not just the main BCDR folder:

| Accelerator/Tool | Path | What It Does | Relevance |
|-----------------|------|-------------|-----------|
| **BCDR Accelerator** | `accelerators/BCDR/` | 3 notebooks: metadata collection in primary, full recovery in DR region (workspace recreation, Git reconnect + sync, lakehouse data copy, warehouse recovery, role assignments, notebook rebinding, semantic model reconnect, pipeline rewiring, report rebind) | **Core** — primary automation for Steps 2-4 |
| **DW Backup & Recovery** | `accelerators/data-warehouse-backup-and-recovery/` | Dedicated warehouse playbook with PowerShell + SQL scripts: `ScriptFabricDWSecurity.sql` (backup DW permissions), `ScriptWorkspacePermissions.ps1` (backup workspace roles), `RecreateArtifacts.ps1` (create workspace + assign capacity + Git connect + sync + create staging LH + shortcuts), `IngestDataIntoDeployedWarehouse.sql` (generate INSERT INTO commands) | **Complementary** — more granular warehouse-specific backup/recovery |
| **Mirror Lakehouse** | `accelerators/mirror-lakehouse/` | Web app (React + Node.js) that clones/mirrors lakehouses using schema shortcuts + copies views/stored procs from SQL analytics endpoint | **Useful** — for creating read-only replicas or staging lakehouses in DR |
| **Copy Warehouse** | `tools/copy-warehouse/` | C# CLI tool to copy warehouse data to a lakehouse (cross-workspace) | **Useful** — for warehouse-to-lakehouse backup |

#### Other Sources

| Source | What It Covers | Gaps |
|--------|----------------|------|
| **[prwani/multi-region-nonpaired-enterprise-prototype](https://github.com/prwani/multi-region-nonpaired-enterprise-prototype)** (your repo) | 3-step framework for multi-region nonpaired Azure deployments (topology manifest, region scoring, orchestration). Covers Cosmos DB, SQL, AKS, Service Bus, Storage, VMs. Fabric entry in service-matrix is ⚠️ stub only. | Fabric BCDR is not implemented beyond a stub. |
| **[MS Learn: Experience-Specific Guidance](https://learn.microsoft.com/en-us/fabric/security/experience-specific-guidance)** | Detailed per-component recovery steps for all Fabric workloads. | Documentation only — no automation scripts. |

### What Native Fabric Git Integration Handles

Git integration is a **core native capability** for DR. When a workspace is connected to Git (ADO or GitHub), syncing to a new workspace restores item **definitions** (not data). As of 2025, Git integration supports:

| Category | Git-Supported Items |
|----------|-------------------|
| **Data Engineering** | Lakehouse (definition), Notebook, Spark Job Definition, Environment, GraphQL |
| **Data Science** | ML Experiments (preview), ML Models (preview) |
| **Data Factory** | Pipeline, Dataflow gen2, Copy Job, Mirrored Database |
| **Real-Time Intelligence** | Eventhouse, EventStream, KQL Database, KQL Queryset, Real-time Dashboard |
| **Data Warehouse** | Warehouse (preview) |
| **Power BI** | Reports (most), Paginated Reports (preview), Semantic Models |

**What Git CANNOT restore** (requires custom automation — this is where fabric-toolbox notebooks add value):
- ❌ **Data** in Lakehouse tables/files
- ❌ **Data** in Warehouse tables
- ❌ Workspace/DW **security permissions**
- ❌ **Shortcuts** in Lakehouses
- ❌ Pipeline **source/sink connection** rewiring (references old workspace/item IDs)
- ❌ Notebook **default lakehouse** attachment
- ❌ Semantic model **bindings** to lakehouse/warehouse (Direct Lake needs rebinding)
- ❌ **Schedule** configurations
- ❌ **OneLake cache**, gateway, and network security settings

### How fabric-toolbox BCDR Notebooks Use Native Capabilities

The BCDR accelerator is already **native-first** — it automates Git reconnect + sync as its core mechanism (Stage 6), then layers on custom automation for everything Git can't handle:

| fabric-toolbox Stage | Native Feature Used | Custom Value Added |
|---------------------|--------------------|--------------------|
| Stage 4: Recover metadata | OneLake ABFS access | Copy metadata tables from DR storage |
| Stage 5: Recreate workspaces | Fabric REST API `POST /v1/workspaces` | Batch creation from saved metadata |
| **Stage 6: Git connect + sync** | **Fabric Git Integration API** | Automates reconnect + update for all workspaces |
| Stage 7: Lakehouse data copy | OneLake ABFS + `notebookutils.fs.cp` | Batch copy of all tables/files across workspaces |
| Stages 8-9: Warehouse recovery | Lakehouse shortcuts + T-SQL | Staging lakehouse + copy pipeline orchestration |
| Stage 10: Role assignments | Fabric REST API | Replay saved role assignments |
| Notebook rebinding | Fabric REST API | Update default lakehouse references |
| Semantic model reconnect | `semantic-link-labs` library | Direct Lake model rebinding |
| Pipeline rewiring | Fabric REST API | Update source/sink workspace/item IDs |
| Report rebinding | Fabric REST API + `semantic-link-labs` | Rebind to new semantic models |

**Conclusion**: The fabric-toolbox notebooks are NOT redundant with Git — they orchestrate Git sync AND handle everything Git can't. They should be adopted as the core recovery engine.

---

## Critical: How Data Copy Works When Primary Region Is Down

This is the most important concept in the plan. The MS Learn diagram ([disaster-recovery-scenario.png](https://learn.microsoft.com/en-us/fabric/security/media/experience-specific-guidance/disaster-recovery-scenario.png)) shows three states:

```
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
│ BEFORE DISASTER     │   │ AFTER FAILOVER       │   │ AFTER RECOVERY      │
│                     │   │                      │   │                     │
│ Region A (Primary)  │   │ Region A: DOWN ❌    │   │ Region A: DOWN ❌   │
│  C1.W1 → active     │   │                      │   │                     │
│  OneLake data       │   │ Region B:            │   │ Region B:           │
│                     │   │  DR replica of       │   │  C2.W2 (new)        │
│ Region B (Paired)   │   │  C1.W1 data          │   │  ✅ Full function   │
│  DR replica         │   │  (read-only via      │   │  Data copied from   │
│  (async replication)│   │   original ABFS      │   │  DR replica →       │
│                     │   │   paths through       │   │  new items          │
│                     │   │   global endpoint)    │   │                     │
└─────────────────────┘   └─────────────────────┘   └─────────────────────┘
```

### The Key Mechanism

1. **Pre-disaster**: When DR is enabled on capacity C1, OneLake **asynchronously replicates all data to the Azure-paired Region B**. This happens continuously in the background.

2. **When disaster strikes**: Region A goes down. Microsoft initiates a **OneLake failover to Region B**. After failover completes, the **original ABFS paths** (e.g., `abfss://<C1.W1>@onelake.dfs.fabric.microsoft.com/<LH>.Lakehouse/Tables/...`) now **resolve to the DR replica in Region B** via the OneLake global endpoint. The data is **read-only**.

3. **"Copy data from C1.W1 to C2.W2"** means: Copy from the **DR replica** (which is in Region B, accessible via the original workspace's ABFS paths) → to the **new items** you created in C2.W2. **You are NOT reaching back to the downed Region A.** The data is already in Region B.

4. **This is exactly what fabric-toolbox automates**: The BCDR notebook NB02 Stage 7 uses:
   ```python
   src_path = f'abfss://{p_bcdr_workspace_src}@onelake.dfs.fabric.microsoft.com/{p_bcdr_lakehouse_src}.Lakehouse'
   # After failover, this path resolves to the DR replica in Region B
   notebookutils.fs.cp(source, destination, True)
   ```

5. **Data loss caveat**: Since replication is **asynchronous**, any data written to OneLake between the last successful replication and the disaster event is lost. (This is the RPO — Recovery Point Objective.)

### Non-Paired Region: No DR Replica Exists

For non-paired regions, OneLake DR does NOT replicate data anywhere. There is no automatic DR replica. So:
- **You must proactively backup data** to a secondary location (e.g., Azure Storage Account in another region) **before** a disaster occurs
- If you haven't backed up, and the primary region goes down, the data is unavailable until Microsoft recovers Region A
- Our non-paired extension notebooks address this by scheduling periodic exports

### What This Means for Our Plan

| Step | Paired Region | Non-Paired Region |
|------|--------------|-------------------|
| **Step 3: Copy data** | Copy FROM **DR replica** (already in Region B, accessible via original ABFS paths after failover) → TO new items in C2.W2 | Copy FROM **pre-disaster backup** in Storage Account → TO new items in C2.W2 |
| **Data source for copy** | OneLake global endpoint (same ABFS paths, read-only after failover) | Azure Storage Account (must have been populated before disaster) |
| **Automation** | ✅ fabric-toolbox BCDR NB02 Stages 7-9 | NEW: backup + restore notebooks needed |

---

## Plan: Organized Around the 4-Step Recovery Model

### Overview

The repo will be organized as a guided demonstration with docs, config, and automation. It will:
1. Reference and adopt fabric-toolbox accelerators as the primary recovery engine
2. Add a Bicep template for capacity provisioning (Step 1 — not covered by fabric-toolbox)
3. Add non-paired-region extensions where no native DR replication exists
4. Integrate the DW Backup & Recovery playbook for richer warehouse coverage
5. Provide comprehensive documentation tying everything together

```
fabric-bcdr-demo/
├── README.md                             # Overview, quick start, architecture
├── docs/
│   ├── architecture.md                   # Paired vs non-paired diagrams
│   ├── paired-region-guide.md            # Paired-region walkthrough
│   ├── nonpaired-region-guide.md         # Non-paired-region walkthrough
│   ├── native-vs-custom-matrix.md        # Per-item: what's native, what needs scripts
│   ├── prerequisites.md                  # Subscription, capacity, permissions
│   └── fabric-toolbox-inventory.md       # Maps all fabric-toolbox assets we use
├── config/
│   ├── bcdr-config.example.json          # Configuration template
│   └── bcdr-config.schema.json           # JSON Schema
├── step0-primary-setup/                  # Pre-disaster setup
│   ├── scripts/                          # Capacity + workspace + items via REST APIs
│   ├── notebooks/                        # Sample data seeding
│   └── docs/enable-dr-guide.md           # Manual DR enablement (no API)
├── step1-provision-dr-capacity/          # Step 1: Create C2
│   ├── bicep/fabric-capacity.bicep       # NEW: ARM/Bicep template
│   └── scripts/provision-capacity.sh     # NEW: CLI wrapper
├── step2-recreate-workspace-items/       # Step 2: Create W2 + items
│   ├── README.md                         # Maps to fabric-toolbox Stages 5, 6
│   └── reference/                        # Links to fabric-toolbox notebooks
├── step3-copy-data/                      # Step 3: Copy data
│   ├── paired/README.md                  # Maps to fabric-toolbox Stages 7, 8, 9
│   ├── paired/reference/                 # Links to fabric-toolbox notebooks
│   └── nonpaired/                        # NEW: Cross-region backup/restore
│       ├── scheduled-backup.ipynb        # NEW: Periodic export to Storage Account
│       └── restore-from-storage.ipynb    # NEW: Restore from non-paired storage
├── step4-restore-full-function/          # Step 4: Per-component restore
│   ├── README.md                         # Maps to fabric-toolbox remaining stages
│   ├── reference/                        # Links to fabric-toolbox notebooks
│   ├── dw-security/                      # Adopted from DW Backup & Recovery accelerator
│   └── validation/                       # NEW: Validation notebook + script
├── e2e-demo/                             # End-to-end demo orchestration
│   ├── run-paired-demo.sh
│   └── run-nonpaired-demo.sh
└── ATTRIBUTION.md                        # Upstream credits
```

---

## Step 0: Primary Setup & DR Enablement (Pre-Disaster)

**Goal**: Set up Fabric in the primary region with key components and enable DR.

| Task | How | Source |
|------|-----|--------|
| Create primary Fabric capacity | **Native**: ARM REST API / Bicep | **New**: Bicep template (reused in Step 1) |
| Create primary workspace(s) | **Native**: Fabric REST API `POST /v1/workspaces` | **New**: Script |
| Create Lakehouse, Warehouse, Notebook, Pipeline | **Native**: Fabric REST API `POST /v1/workspaces/{id}/items` | **New**: Script |
| Seed sample data into Lakehouse/Warehouse | Notebook | **New**: Sample data notebook |
| Enable DR on capacity | **Native**: Admin Portal UI only (⚠️ no API) | **New**: Screenshot guide |
| Connect workspace to Git (ADO/GitHub) | **Native**: Fabric REST API `/v1/workspaces/{id}/git/connect` | **New**: Script |
| Collect metadata for recovery | Fabric REST API + OneLake storage | **✅ fabric-toolbox** `01 - Run In Primary.ipynb` + `workspaceutils.ipynb` |
| Backup DW security | T-SQL script | **✅ fabric-toolbox** `data-warehouse-backup-and-recovery/_BackupScripts/ScriptFabricDWSecurity.sql` |
| Backup workspace permissions | PowerShell + Fabric REST API | **✅ fabric-toolbox** `data-warehouse-backup-and-recovery/_BackupScripts/ScriptWorkspacePermissions.ps1` |

---

## Step 1: Create New Fabric Capacity C2 in DR Region

**Goal**: Provision a new Fabric capacity in the secondary region.

| Task | How | Source |
|------|-----|--------|
| Provision F-capacity (paired or non-paired) | **Native**: ARM REST API `PUT /subscriptions/.../Microsoft.Fabric/capacities/{name}` | **New**: `bicep/fabric-capacity.bicep` + `scripts/provision-capacity.sh` |
| Validate capacity provisioning | **Native**: ARM API GET + poll | Included in script above |

**Note**: fabric-toolbox BCDR notebooks assume capacity already exists. The DW Recovery playbook says "manually provision" via Azure Portal. Our Bicep template fills this gap.

---

## Step 2: Create Workspace W2 with Same Items as W1

**Goal**: Recreate workspace structure and items in the new capacity.

This step is **almost entirely covered by native Git integration + fabric-toolbox automation**:

| Task | How | Source |
|------|-----|--------|
| Create workspace(s) in C2 | **Native**: Fabric REST API | **✅ fabric-toolbox** BCDR NB02 Stage 5 |
| Connect workspaces to Git + sync items | **Native**: Git Integration API | **✅ fabric-toolbox** BCDR NB02 Stage 6 |
| All Git-supported items restored (Lakehouse def, Notebook, Pipeline, Warehouse def, Dataflow, etc.) | **Native**: Git sync | Happens automatically in Stage 6 |
| Apply workspace role assignments | **Native**: Fabric REST API | **✅ fabric-toolbox** BCDR NB02 Stage 10 |
| *Alternative*: PowerShell-based workspace + Git reconnect + DW artifacts | PowerShell + REST API | **✅ fabric-toolbox** `data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1` |

**New work**: Only documentation mapping each item type to its recovery path.

---

## Step 3: Copy Data from Disrupted C1.W1 to C2.W2

**Goal**: Restore data into the recreated items.

**⚠️ Important**: In the paired-region scenario, the primary region IS down — but the data is NOT lost. It was asynchronously replicated to Region B before the disaster. After OneLake failover, the original ABFS paths resolve to the DR replica in Region B (read-only). The copy operation reads from this DR replica. See "Critical: How Data Copy Works" section above.

### Paired Region (OneLake DR replica available in Region B)

| Task | How | Source |
|------|-----|--------|
| Copy Lakehouse Delta tables + files | `notebookutils.fs.cp` from **DR replica** (original ABFS paths, now in Region B after failover) | **✅ fabric-toolbox** BCDR NB02 Stage 7 |
| Copy Warehouse data via staging Lakehouse + shortcuts + T-SQL | Lakehouse shortcuts point to **DR replica** → INSERT INTO | **✅ fabric-toolbox** BCDR NB02 Stages 8-9 |
| *Alternative*: Warehouse recovery via staging LH | Shortcuts + INSERT INTO generators | **✅ fabric-toolbox** `data-warehouse-backup-and-recovery/_RecoveryScripts/IngestDataIntoDeployedWarehouse.sql` |
| *Alternative*: Copy warehouse to lakehouse | C# CLI tool | **✅ fabric-toolbox** `tools/copy-warehouse/` |

### Non-Paired Region (No OneLake DR data — fully custom)

| Task | How | Source |
|------|-----|--------|
| Periodic data export to secondary-region Storage | Scheduled notebook/pipeline to copy OneLake → Storage Account | **New**: `nonpaired/scheduled-backup.ipynb` |
| Restore from Storage → new Lakehouse | Notebook adapting fabric-toolbox copy patterns | **New**: `nonpaired/restore-from-storage.ipynb` |
| Warehouse from non-paired backup | Same staging LH pattern, different source | **New**: Adapt fabric-toolbox warehouse stages |

**Alternatively for non-paired**: The `mirror-lakehouse` web app could be adapted to create cross-region mirrors as a proactive backup mechanism.

---

## Step 4: Restore Items to Full Function

**Goal**: Per-component post-recovery steps to achieve full operational state.

| Task | How | Source |
|------|-----|--------|
| Rebind notebook default lakehouse | Fabric REST API | **✅ fabric-toolbox** BCDR NB02 |
| Reconnect Direct Lake semantic models | `semantic-link-labs` | **✅ fabric-toolbox** BCDR NB02 |
| Update pipeline source/sink connections | Fabric REST API | **✅ fabric-toolbox** BCDR NB02 |
| Rebind reports | Fabric REST API + `semantic-link-labs` | **✅ fabric-toolbox** BCDR NB02 |
| Restore DW security permissions | Replay saved SQL scripts | **✅ fabric-toolbox** `data-warehouse-backup-and-recovery` (output of backup scripts) |
| Restore workspace permissions | Replay saved PowerShell | **✅ fabric-toolbox** `data-warehouse-backup-and-recovery` (output of backup scripts) |
| Validate end-to-end | Custom | **New**: Validation notebook + script |
| Additional manual items (MLV, Mirrored DB, KQL, etc.) | Per MS Learn docs | **New**: Documentation only |

---

## Summary: Native vs fabric-toolbox vs New Work

### Three-Layer Model

```
┌─────────────────────────────────────────────────┐
│ Layer 3: NEW WORK (this repo)                   │
│  • Bicep capacity template (Step 1)             │
│  • Primary setup scripts (Step 0)               │
│  • Non-paired backup/restore notebooks          │
│  • Sample data seeding                          │
│  • E2E demo orchestration                       │
│  • Validation notebook                          │
│  • Comprehensive documentation                  │
├─────────────────────────────────────────────────┤
│ Layer 2: FABRIC-TOOLBOX (adopt/reference)        │
│  • BCDR accelerator (NB01 + NB02 + utils)       │
│  │  Stages 4-10: metadata, workspace, Git sync, │
│  │  LH data copy, WH recovery, roles, rebinding │
│  • DW Backup & Recovery playbook                │
│  │  Security backup, workspace perms,           │
│  │  RecreateArtifacts.ps1, IngestData.sql       │
│  • mirror-lakehouse (optional: proactive DR)    │
│  • copy-warehouse tool (optional: WH → LH)     │
├─────────────────────────────────────────────────┤
│ Layer 1: NATIVE FABRIC CAPABILITIES              │
│  • OneLake DR replication (paired regions)       │
│  • Git Integration (item definitions/code)       │
│  • Fabric REST API (workspaces, items, roles)    │
│  • ARM API (capacity provisioning)               │
│  • Warehouse restore points (in-place)           │
│  • Delta Lake time travel (Lakehouse)            │
└─────────────────────────────────────────────────┘
```

| Area | Layer 1 (Native) | Layer 2 (fabric-toolbox) | Layer 3 (New) |
|------|------------------|-------------------------|---------------|
| DR data replication | ✅ OneLake DR (paired) | — | — |
| Item definitions restore | ✅ Git Integration | Orchestrates Git sync | — |
| Capacity provisioning | ✅ ARM REST API | — | **Bicep template** |
| Workspace creation | ✅ Fabric REST API | ✅ BCDR NB02 Stage 5 | — |
| Git reconnect + sync | ✅ Git Integration API | ✅ BCDR NB02 Stage 6 | — |
| Lakehouse data copy | ✅ OneLake ABFS | ✅ BCDR NB02 Stage 7 | — |
| Warehouse data recovery | ✅ Shortcuts + T-SQL | ✅ BCDR NB02 Stages 8-9, DW Recovery scripts | — |
| Workspace roles | ✅ Fabric REST API | ✅ BCDR NB02 Stage 10, DW Perms scripts | — |
| DW security | — | ✅ DW Security backup script | — |
| Notebook/model rebinding | — | ✅ BCDR NB02 | — |
| Semantic model reconnect | — | ✅ BCDR NB02 (semantic-link-labs) | — |
| Pipeline rewiring | — | ✅ BCDR NB02 | — |
| Non-paired backup | — | — | **New notebook** |
| Non-paired restore | — | — | **New notebook** |
| Primary environment setup | ✅ REST APIs | — | **New scripts** |
| Sample data seeding | — | — | **New notebook** |
| E2E demo orchestration | — | — | **New scripts** |
| Validation | — | — | **New notebook** |
| Comprehensive docs | MS Learn (reference) | PDF guide | **New docs** |

---

## Todos

1. **repo-scaffold** — Create repo structure, README, config schema, ATTRIBUTION.md
2. **step0-primary-setup** — Scripts for capacity + workspace + items via REST APIs, sample data notebook, Git connect script
3. **step0-enable-dr** — Documentation + screenshot guide for DR enablement (no API)
4. **step0-collect-metadata** — Reference fabric-toolbox `01 - Run In Primary.ipynb` + `workspaceutils.ipynb` + DW security backup scripts
5. **step1-provision-capacity** — NEW Bicep template + CLI script for DR capacity provisioning
6. **step2-recreate-workspace** — Reference fabric-toolbox BCDR NB02 Stages 5, 6, 10 + DW RecreateArtifacts.ps1 as alternative
7. **step3-copy-data-paired** — Reference fabric-toolbox BCDR NB02 Stages 7, 8, 9 + DW IngestData.sql
8. **step3-copy-data-nonpaired** — NEW notebooks for scheduled cross-region backup + non-paired restore
9. **step4-restore-function** — Reference fabric-toolbox BCDR NB02 remaining stages + DW security replay + validation notebook
10. **docs-native-matrix** — Native-vs-custom-matrix.md + fabric-toolbox-inventory.md
11. **docs-guides** — Paired-region guide, non-paired-region guide, prerequisites
12. **e2e-demo** — Orchestration scripts for paired and non-paired demo flows
13. **attribution** — Proper attribution to all fabric-toolbox accelerators, MS Learn, upstream repos

### Dependencies
- repo-scaffold blocks everything
- step0 → step1 → step2 → step3-paired → step4 (sequential chain)
- step3-nonpaired depends on repo-scaffold only (parallel track)
- docs, e2e-demo, attribution can proceed in parallel after scaffold
