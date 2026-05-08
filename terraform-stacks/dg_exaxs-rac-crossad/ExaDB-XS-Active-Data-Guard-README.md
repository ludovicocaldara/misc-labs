# ExaDB-XS End-to-End (Active Data Guard)

Provision a complete Oracle ExaDB-XS Active Data Guard environment using
OCI Resource Manager.

This stack creates:

-   Full VCN networking
-   Two Exascale Storage Vaults, one in each selected Availability Domain
-   Two ExaDB-XS RAC VM Clusters across Availability Domains
-   Two DB Homes
-   One Primary CDB
-   One Standby CDB (via Data Guard)
-   Optional Active Data Guard (read-only standby)

> Single-region, cross-Availability-Domain deployment.

------------------------------------------------------------------------

## Architecture Overview

VCN ├── Regional Public Subnet │ ├── AD1: ExaDB-XS Cluster A (Primary) │ └── AD2: ExaDB-XS
Cluster B (Standby) │ └── Regional Backup Subnet (Private)

Primary Exascale Storage Vault (AD1) + Standby Exascale Storage Vault (AD2)

Primary DB (Cluster A) ---\> Standby DB (Cluster B) ASYNC, Maximum
Performance

------------------------------------------------------------------------

# What This Stack Creates

## Networking

-   VCN
-   Internet Gateway
-   NAT Gateway
-   Service Gateway
-   Public Route Table
-   Private Route Table
-   Security List (22, 1521, 5500 open)
-   Public Subnet (for clusters)
-   Backup Subnet (private)

## Database Infrastructure

-   2 × Exascale Storage Vaults, one per selected Availability Domain
-   2 × ExaDB-XS VM Clusters (2-node RAC each), deployed across Availability Domains
-   2 × DB Homes
-   1 × Primary Database (CDB + PDB)
-   1 × Standby Database (created via Data Guard)
-   Data Guard Association (ASYNC, Maximum Performance)

------------------------------------------------------------------------

# Prerequisites

## OCI Requirements

-   Sufficient quota for:
    -   2 × ExaDB-XS VM Clusters
    -   2 × Exascale Storage Vaults
-   IAM permissions:
    -   manage database-family
    -   manage virtual-network-family
    -   manage orm-stacks

------------------------------------------------------------------------

## Grid Infrastructure Image (Critical Requirement)

-   By default, the stack dynamically discovers the Grid Infrastructure
Image OCID for ExaDB-XS separately for each
Availability Domain using the OCI Terraform data source
`oci_database_gi_version_minor_versions`.

The lookup uses:

-   `gi_version` (default: `23.0.0.0`)
-   `primary_availability_domain` for Cluster A
-   `standby_availability_domain` for Cluster B
-   `shape_family = "EXADB_XS"`
-   `compartment_ocid`

Because Grid Infrastructure images are Availability-Domain-specific, the stack
uses separate effective image IDs:

-   `primary_grid_image_id` for the primary AD ExaDB-XS VM Cluster
-   `standby_grid_image_id` for the standby AD ExaDB-XS VM Cluster

If you need to force a specific image in one or both ADs, set the corresponding
AD-specific variable to a valid ExaDB-XS Grid Infrastructure image OCID. If an
AD-specific image ID is empty, Terraform falls back to `grid_image_id` when set,
otherwise it dynamically discovers the image for that AD from `gi_version`.

Example format:

ocid1.dbpatch.oc1.`<region>`{=html}.xxxxx

Important:

-   This OCID is region- and Availability-Domain-specific.
-   It is NOT created by this Terraform stack; it is discovered from OCI
    metadata or supplied as an override.
-   It must be compatible with ExaDB-XS.
-   Deployment will fail if it does not match the selected region and
    Availability Domain.

To retrieve available Grid Infrastructure images:

Using OCI CLI:

oci db patch list\
--compartment-id `<compartment_ocid>`{=html}\
--patch-type GRID_INFRASTRUCTURE\
--region `<region>`{=html}



Or via Console:

Oracle Database → Exadata Infrastructure → Patches

------------------------------------------------------------------------

# Required Inputs

  Variable              Description
  --------------------- -------------------------------------
  compartment_ocid      Target compartment
  primary_availability_domain   AD for primary ExaDB-XS resources
  standby_availability_domain   AD for standby ExaDB-XS resources
  db_admin_password     SYS password (\>=12 chars, complex)
  ssh_public_key        SSH public key for cluster nodes

Optional Grid Infrastructure inputs:

  Variable              Description
  --------------------- -------------------------------------
  gi_version            GI version used for dynamic image lookup (default: 23.0.0.0)
  primary_grid_image_id Optional Grid Infrastructure image OCID override for the primary AD
  standby_grid_image_id Optional Grid Infrastructure image OCID override for the standby AD
  grid_image_id         Optional common fallback override for both ADs

------------------------------------------------------------------------

# Deployment Steps

1.  Go to OCI → Developer Services → Resource Manager
2.  Create Stack
3.  Upload ZIP (main.tf + schema.yaml)
4.  Provide required inputs
5.  Click Plan
6.  Click Apply

Estimated provisioning time: 2--4 hours.

------------------------------------------------------------------------

# Post-Deployment Validation

Check Database Role:

SELECT database_role FROM v\$database;

Primary should show: PRIMARY\
Standby should show: PHYSICAL STANDBY

Check Data Guard processes:

SELECT process, status FROM v\$managed_standby;

Expect: - RFS running - MRP running

------------------------------------------------------------------------

# Important Notes

-   Single-region, cross-Availability-Domain deployment (not cross-region DR).
-   Security list allows inbound from 0.0.0.0/0 (not production
    hardened).
-   Auto-backup is disabled.
-   Protection mode is MAXIMUM_PERFORMANCE.
-   Terraform does not manage runtime switchover/failover state.

------------------------------------------------------------------------

# Destroying the Environment

From Resource Manager:

1.  Open the Stack
2.  Click Destroy

This removes all networking, clusters, DB Homes, databases, and Data
Guard configuration.

Destruction is irreversible.

------------------------------------------------------------------------

# Summary

This stack provisions a complete ExaDB-XS Active Data Guard environment
in a single region across two Availability Domains, including networking and storage.

The stack discovers valid, region- and AD-matching Grid Infrastructure image
OCIDs automatically unless `primary_grid_image_id`, `standby_grid_image_id`, or
the common fallback `grid_image_id` are supplied as overrides.
