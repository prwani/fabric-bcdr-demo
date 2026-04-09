# Validation assets

The recovered environment should be validated before it is declared operational.

## Minimum checks

- target capacity exists and is reachable
- expected workspaces and supported Fabric items exist
- lakehouse tables and files are present
- warehouse objects and data are queryable
- notebooks point at the correct default lakehouse
- pipelines reference the new workspace and item IDs
- semantic models and reports bind to recovered data sources
- workspace and warehouse permissions were replayed successfully

## Implemented assets

- `validate-recovery.sh` — checks that the target capacity, workspace, and expected core artifacts exist
- `validate-recovery.ipynb` — validates lakehouse sample tables and row counts from inside Fabric
- `validate-warehouse.sql` — validates warehouse sample tables and row counts
- `e2e-demo/smoke-test-paired.sh` and `e2e-demo/smoke-test-nonpaired.sh` — CLI entrypoints that call the validation wrapper

## Usage

```bash
./step4-restore-full-function/validation/validate-recovery.sh \
  --capacity-display-name fabricdrdemo \
  --workspace-name fabric-bcdr-dr \
  --lakehouse-name bcdr_demo_lakehouse \
  --warehouse-name bcdr_demo_warehouse \
  --notebook-name bcdr_seed_sample_data \
  --pipeline-name bcdr_demo_pipeline \
  --spark-job-name bcdr_demo_spark_job
```

Run `validate-recovery.ipynb` from the recovered lakehouse-attached workspace to validate the lakehouse tables, and run `validate-warehouse.sql` in the recovered warehouse SQL editor to validate warehouse tables and rows.
