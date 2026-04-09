# Prerequisites

## Azure and Fabric access

You need:

- An Azure subscription that can deploy `Microsoft.Fabric/capacities`
- Permission to create or update resources in the target resource group
- Fabric admin or capacity admin access appropriate for the workspaces and capacities involved
- Workspace admin access for the source and target Fabric workspaces
- A Git repository that will hold Fabric item definitions

## Local tools

The current repo assets assume:

- `bash`
- `git`
- `curl`
- `az` (Azure CLI) with an authenticated session
- `jq`
- `python3`

Optional but useful:

- `sqlcmd`, Azure Data Studio, SSMS, or another TDS-capable SQL client for warehouse seed and validation scripts
- A notebook-capable Fabric environment for running the upstream and repo-owned custom notebooks
- A local clone of `https://github.com/prwani/fabric-toolbox` if you want to launch the referenced upstream notebooks and scripts from disk

## Azure setup

Before running Step 1:

1. Register the `Microsoft.Fabric` resource provider in the subscription if it is not already registered.
2. Create or choose a resource group in the DR region.
3. Confirm that the desired Fabric SKU is available in the target region.
4. Identify the Entra user principals that should administer the DR capacity.

## Fabric setup

Before running the full demo:

1. Create the primary Fabric capacity.
2. Run the repo bootstrap flow in `step0-primary-setup/`.
3. Connect the primary workspace to Git or let the bootstrap script do it for you.
4. Enable OneLake DR on the primary capacity for the paired-region scenario.
5. Schedule cross-region backups for the non-paired-region scenario.

## Configuration

Use `config/bcdr-config.example.json` as the starting point for local execution. The file is intentionally not committed as `config/bcdr-config.json` so tenant-specific values stay local.
