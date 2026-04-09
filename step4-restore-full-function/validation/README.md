# Validation plan

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

## Planned assets

- a validation notebook
- a CLI-friendly validation wrapper
- sample smoke tests for paired and non-paired demo runs
