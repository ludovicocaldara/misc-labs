# ExaDB-XS RAC DGPDB Prerequisites

This stack provisions the infrastructure needed to create a Data Guard per
Pluggable Database (DGPDB) configuration on Oracle RAC, without creating a
conventional Data Guard group.

It creates:

- A VCN, public VM-cluster subnet, and private backup subnet.
- One shared Exascale Storage Vault.
- Two two-node ExaDB-XS RAC VM clusters in the same Availability Domain.
- One new, independent RAC CDB in a separate DB home on each cluster:
  `dgpdb1` on Cluster A and `dgpdb2` on Cluster B by default.

Both `oci_database_database` resources use `source = "NONE"`. The stack does
not create a database with `source = "DATAGUARD"`, does not set a source
database ID, and does not create a conventional primary/standby relationship.
The two CDBs are peers that you prepare and join with Data Guard Broker in the
subsequent DGPDB workflow.

## Database Layout

| VM cluster | RAC CDB | Terraform source | Intended role |
| --- | --- | --- | --- |
| Cluster A | `dgpdb1` | `NONE` | DGPDB peer CDB |
| Cluster B | `dgpdb2` | `NONE` | DGPDB peer CDB |

The initial PDB in both CDBs is `mypdb` by default. Override `dgpdb1_name`,
`dgpdb2_name`, and `pdb_name` in `terraform.tfvars` as needed.

## Required Inputs

Provide `compartment_ocid` and a compliant `db_admin_password`. The supplied
Availability Domain default works for the validated tenancy only; replace it
when deploying from another tenancy. An SSH public key is optional but is
recommended for the manual RAC and DGPDB preparation that follows provisioning.

## Validated London Defaults

The defaults are aligned to the validated UK South ExaDB-XS lookup:

| Input | Default / example value |
| --- | --- |
| `region` | `uk-london-1` |
| `availability_domain` | `OUGC:UK-LONDON-1-AD-1` |
| `gi_version` | `23.0.0.0` |
| Discovered GI image version | `23.26.3.0.0` |
| `db_version` | `23.26.3.0.0` |

`grid_image_id` remains empty by default. Terraform discovers the image from
the GI version and Availability Domain, so the image OCID is not pinned.
Availability Domain names are tenancy-specific; replace the `OUGC:`-prefixed
value when deploying from another tenancy.

## After Terraform Apply

Use the DGPDB preparation steps in
[`dataguard/demos/exaxs-dg-to-dgpdb/migrate-existing-pdb-to-dgpdb.md`](../../dataguard/demos/exaxs-dg-to-dgpdb/migrate-existing-pdb-to-dgpdb.md),
starting with the preparation of the two DGPDB CDBs. Configure Broker, shared
Broker files, Oracle Net connectivity, wallets, and `PREPARE DGPDB` manually.
Those runtime settings deliberately remain outside Terraform so this stack is
safe to use as a clean DGPDB starting point.

## Notes

- This is a single-region, single-Availability-Domain lab topology.
- The shared security list admits SSH, listener, and EM Express from
  `0.0.0.0/0`. Restrict those rules before using this pattern outside a lab.
- Auto-backup is disabled for both CDBs, matching the migration-lab stack.
- DB home creation is serialized, with configurable waits for transient OCI
  control-plane capacity errors.
