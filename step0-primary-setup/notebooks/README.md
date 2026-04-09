# Step 0 notebooks

This folder contains the notebook used to seed the primary demo lakehouse.

## Implemented notebook

- `seed-sample-data.ipynb`
  - creates a synthetic retail-style star schema
  - writes sample Delta tables into the primary lakehouse
  - gives the paired and non-paired DR flows real data to restore

## Upstream inspiration

The implementation pattern follows the Fabric healthcare sample found in:

- `multi-region-nonpaired-enterprise-prototype/step1-primary-baseline/scripts/setup-fabric-healthcare.sh`
- `multi-region-nonpaired-enterprise-prototype/step1-primary-baseline/samples/E-fabric-healthcare/cms_healthcare_demo.ipynb`

## Upstream notebook references

- `fabric-toolbox/accelerators/BCDR/01 - Run In Primary.ipynb`
- `fabric-toolbox/accelerators/BCDR/workspaceutils.ipynb`
