# Step 0: build the primary Fabric environment

This step creates the **source environment** that the BCDR demo later protects and recovers.

## What this repo now implements

- `scripts/bootstrap-primary-workspace.sh` creates the primary workspace, assigns it to the Fabric capacity, creates sample artifacts, optionally connects the workspace to Git, and optionally runs the sample-data notebook.
- `notebooks/seed-sample-data.ipynb` seeds synthetic sample data into the primary **lakehouse**.
- `sql/seed-warehouse.sql` seeds synthetic sample data into the primary **warehouse**.

## How the primary environment is populated

After the primary capacity exists, the repo uses this split:

1. **Workspace + artifact creation**
   - Workspace
   - Lakehouse
   - Warehouse
   - Notebook
   - Data pipeline
   - Spark job definition
   - Optional Git connection + initial commit

2. **Lakehouse sample data**
   - Seeded by `notebooks/seed-sample-data.ipynb`
   - Triggered automatically by `bootstrap-primary-workspace.sh` unless `--skip-seed-notebook` is used

3. **Warehouse sample data**
   - Seeded by `sql/seed-warehouse.sql`
   - Executed through the warehouse SQL interface after the warehouse is created

## Upstream seeding examples checked

- **`fabric-toolbox`**: I did **not** find a BCDR-specific sample-data seeding asset in `accelerators/BCDR/`.
- **`multi-region-nonpaired-enterprise-prototype`**: I did find a reusable Fabric seeding pattern:
  - `step1-primary-baseline/scripts/setup-fabric-healthcare.sh`
  - `step1-primary-baseline/samples/E-fabric-healthcare/cms_healthcare_demo.ipynb`

This repo's Step 0 implementation follows that same pattern: create the Fabric items with APIs, upload a notebook definition, and run it to generate synthetic data.

## Usage

```bash
./step0-primary-setup/scripts/bootstrap-primary-workspace.sh \
  --capacity-display-name fabricprimarydemo \
  --workspace-name fabric-bcdr-primary \
  --lakehouse-name bcdr_demo_lakehouse \
  --warehouse-name bcdr_demo_warehouse \
  --notebook-name bcdr_seed_sample_data \
  --pipeline-name bcdr_demo_pipeline \
  --spark-job-name bcdr_demo_spark_job
```

### With Git integration

```bash
./step0-primary-setup/scripts/bootstrap-primary-workspace.sh \
  --capacity-display-name fabricprimarydemo \
  --workspace-name fabric-bcdr-primary \
  --git-provider github \
  --git-owner prwani \
  --git-repository-name fabric-bcdr-demo \
  --git-branch main \
  --git-directory fabric-primary \
  --git-connection-id 00000000-0000-0000-0000-000000000000
```

## Notes

- The script resolves the **Fabric capacity UUID** from the capacity display name by calling `GET /v1/capacities`.
- The lakehouse data path is fully automated.
- Warehouse data seeding uses the SQL surface because warehouse DDL/DML is executed through T-SQL rather than the core REST item APIs.
- After the primary environment is populated, run the upstream `fabric-toolbox/accelerators/BCDR/01 - Run In Primary.ipynb` notebook to capture recovery metadata.

