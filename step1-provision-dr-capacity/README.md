# Step 1: provision DR capacity

This step fills a deliberate gap in the upstream toolbox: provisioning the **new Microsoft Fabric capacity** that receives the recovered workspaces.

## What is implemented here

- `bicep/fabric-capacity.bicep` creates a `Microsoft.Fabric/capacities` resource
- `scripts/provision-capacity.sh` validates inputs, optionally registers the resource provider, and deploys the Bicep template with Azure CLI

## Prerequisites

- Review [docs/prerequisites.md](../docs/prerequisites.md)
- Run `az login`
- Ensure your target subscription and resource group are correct

## Usage

```bash
./step1-provision-dr-capacity/scripts/provision-capacity.sh \
  --subscription-id 00000000-0000-0000-0000-000000000000 \
  --resource-group rg-fabric-bcdr-demo \
  --capacity-name fabricdrdemo \
  --location westus2 \
  --sku F2 \
  --admin-members fabric.admin@contoso.com,ops.admin@contoso.com \
  --tags-json '{"solution":"fabric-bcdr-demo","scenario":"paired"}'
```

### Preview changes only

```bash
./step1-provision-dr-capacity/scripts/provision-capacity.sh \
  --subscription-id 00000000-0000-0000-0000-000000000000 \
  --resource-group rg-fabric-bcdr-demo \
  --capacity-name fabricdrdemo \
  --location westus2 \
  --admin-members fabric.admin@contoso.com \
  --what-if
```

## Inputs

| Argument | Required | Notes |
|----------|----------|-------|
| `--subscription-id` | Yes | Azure subscription containing the resource group |
| `--resource-group` | Yes | Existing resource group for deployment |
| `--capacity-name` | Yes | Must match Fabric naming constraints: lowercase, starts with a letter |
| `--location` | Yes | Azure region for the DR capacity |
| `--admin-members` | Yes | Comma-separated Entra user principal names |
| `--sku` | No | Defaults to `F2` |
| `--tags-json` | No | JSON object string, defaults to `{}` |
| `--what-if` | No | Runs Azure deployment preview instead of create/update |
| `--skip-provider-registration` | No | Skips automatic `Microsoft.Fabric` provider registration check |

## Outputs

The script prints a compact JSON summary of the deployed capacity after Azure reports success.
