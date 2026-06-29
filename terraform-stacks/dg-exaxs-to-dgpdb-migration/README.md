# ExaDB-XS Data Guard PDB Migration Setup

This stack prepares a two-cluster ExaDB-XS RAC topology for Data Guard
PDB migration testing.

It creates:

- Full VCN networking
- Shared Exascale Storage Vault
- Cluster A and Cluster B, each as a 2-node ExaDB-XS RAC VM Cluster
- Four RAC databases in total
- A Data Guard group only between RAC DB 1 and RAC DB 3

## Database Layout

| VM cluster | Database | Role / protection |
| --- | --- | --- |
| Cluster A | RAC DB 1 | Primary in Data Guard group |
| Cluster A | RAC DB 2 | Independent RAC DB, not in Data Guard |
| Cluster B | RAC DB 3 | Physical standby for RAC DB 1 |
| Cluster B | RAC DB 4 | Independent RAC DB, not in Data Guard |

## Data Guard

RAC DB 3 is created with `oci_database_database` using
`source = "DATAGUARD"` and `source_database_id` pointing to RAC DB 1.
The protection mode is `MAXIMUM_PERFORMANCE` with `ASYNC` transport.

RAC DB 2 and RAC DB 4 are ordinary independent databases created with
`source = "NONE"`.

## Inputs

The default CDB names are:

- `db_name = "racdb1"` for RAC DB 1
- `db2_name = "racdb2"` for RAC DB 2
- `db4_name = "racdb4"` for RAC DB 4

The standby database, RAC DB 3, derives its `db_unique_name` from RAC DB
1 as `${db_name}_site2`.

## Notes

- Single-region deployment in one Availability Domain.
- Security list allows inbound SSH, listener, and EM Express from
  `0.0.0.0/0`; harden this before production use.
- Auto-backup is disabled for the independent and primary databases.
- Terraform does not manage runtime switchover or failover state.
