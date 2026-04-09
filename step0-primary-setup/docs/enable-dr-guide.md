# Enable DR on the primary Fabric capacity

Fabric capacity DR enablement is currently a **manual admin action**. There is no public API in this repo for toggling it.

## Goal

Enable OneLake disaster recovery for the primary capacity so paired-region data replication is active before a disaster occurs.

## Operator flow

1. Open the Fabric admin portal.
2. Navigate to the target primary capacity.
3. Open the capacity disaster-recovery settings.
4. Enable OneLake DR for the capacity.
5. Save the setting and document the change in your runbook.
6. Wait for the setting to become active before assuming replicated protection exists.

## Verify

- The capacity shows DR enabled in the admin experience.
- The team understands the **asynchronous replication** model and its RPO implications.
- Recovery operators know which paired region will host the replica during failover.

## Notes

- DR enablement affects the **paired-region** flow only.
- This does **not** provision a new secondary capacity; that is Step 1 in this repo.
