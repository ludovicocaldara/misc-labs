# Convert an Existing PDB in a Data Guard Configuration to Data Guard per Pluggable Database

## About This Playbook

This playbook describes how to convert an existing pluggable database (PDB) that is protected as part of a conventional Oracle Data Guard configuration into a PDB protected by Data Guard per Pluggable Database (DGPDB).

The example was developed and validated in an Oracle AI Database 26ai Release 23.26.2.0.0 environment on Oeacle Exadata Database Service on Exascale Inftastructure (ExaDB-XS). The reference environment consists of two Oracle Grid Infrastructure clusters. Each cluster hosts:

- One CDB that participates in the DGPDB configuration.
- One member of the existing conventional Data Guard configuration.

The same cluster nodes therefore host both the DGPDB CDB and the conventional Data Guard database. The example uses the following logical names:

| Component | Cluster 1 | Cluster 2 |
|---|---|---|
| DGPDB CDB | `dgpdb1` | `dgpdb2` |
| Conventional Data Guard database | `dgcdb` primary database | `dgcdb` standby database |
| Existing PDB to convert | `MYPDB` in the primary database | `MYPDB` in the standby database |
| Initial DGPDB placement | Source PDB in `dgpdb1` | Target PDB in `dgpdb2` |

In a DGPDB configuration, the CDBs are peers. They do not have primary and standby roles, both are primary CDBs. The source and target roles apply to each protected PDB and can reverse after a PDB switchover.

Adapt all names and values in this playbook to your environment, including:

- Cluster and node names
- Database unique names and instance names
- PDB names
- SCAN names and service names
- Oracle Net configuration locations
- Shared storage paths
- TDE keystore paths and passwords
- Data file names and storage locations
- Exascale vault and wallet identifiers, when applicable

> **Caution:** This procedure closes, unplugs, and drops the PDB from the conventional Data Guard primary database while retaining its data files. Test the complete procedure and rollback plan in a nonproduction environment before using it for a production PDB.

## Scope

The playbook includes the following tasks:

1. Prepare both DGPDB CDBs and their RAC instances.
2. Create and prepare the DGPDB Broker configuration.
3. Optionally configure and validate the DGPDB environment with existing PDBs, including TDE key exchange, apply, and PDB switchovers.
4. Capture the existing target-side data file locations for the PDB being converted.
5. Export and distribute the PDB TDE keys.
6. Unplug the PDB from the conventional Data Guard primary database.
7. Plug the PDB into one DGPDB CDB without copying its source data files.
8. Register the target PDB in the peer DGPDB CDB without copying its existing target data files.
9. Remap the target PDB data file names.
10. Enable apply for the target PDB.
11. Open and validate the target PDB.
12. Validate the configuration and test PDB switchovers.
13. Complete post-conversion checks.

## Before You Begin

Ensure that the following requirements are met:

- Both DGPDB CDBs are Oracle RAC databases and are reachable from both clusters by Oracle Net.
- `FLASHBACK DATABASE` and force logging are configured as required by your deployment standards.
- Data Guard Broker is enabled in both DGPDB CDBs.
- The Broker configuration files are stored on shared storage that is accessible to every RAC instance of the corresponding CDB.
- The same administrative credentials can be used by Broker to connect to both DGPDB CDBs, or an equivalent secure credential arrangement is configured.
- TDE is configured and the keystores are available on all required RAC instances.
- The source PDB and its target copy in the conventional Data Guard configuration are synchronized before conversion.
- You have a current backup and a tested recovery plan.
- You have recorded the data file locations for both copies of the PDB.
- You have privileges to run SQL as `SYSDBA`, run `DGMGRL`, manage Clusterware resources with `srvctl`, manage TDE keys, and inspect storage vault where required.

> **Note:** Commands that modify files under `$TNS_ADMIN` must be applied consistently on every RAC node from which the corresponding database instance can run, unless the files are stored in a shared location.

## Naming Used in the Examples

| Placeholder or example | Meaning |
|---|---|
| `dgpdb1` | DGPDB CDB on Cluster 1 |
| `dgpdb2` | DGPDB CDB on Cluster 2 |
| `dgpdb11`, `dgpdb12` | RAC instances of `dgpdb1` |
| `dgpdb21`, `dgpdb22` | RAC instances of `dgpdb2` |
| `dgcdb` | Conventional Data Guard database name used in the demo |
| `MYPDB` | Existing PDB on `dgcdb` being converted |
| `PDB1` | Pre-created PDB on `dgpdb1` |
| `PDB2` | Pre-created PDB on `dgpdb2` |
| `my_strong_password` | Example placeholder for the TDE and wallet secret; do not use this literal value |

## 1. Prepare the DGPDB CDB on Cluster 1

Perform this task on Cluster 1 with the Oracle environment for `dgpdb1` set.

### 1.1 Configure Broker and File Management Parameters

Create a shared directory for the Broker configuration files. The path must be accessible from all RAC instances of `dgpdb1`.

```shell
mkdir -p /var/opt/oracle/dbaas_acfs/dgpdb1/dg_config_file
```

Connect to `dgpdb1` as `SYSDBA` and verify the current database settings:

```sql
SELECT flashback_on, force_logging FROM v$database;
SHOW PARAMETER standby_file_management
SHOW PARAMETER dg_broker
```

Set automatic standby file management and configure the Broker files on shared storage:

```sql
ALTER SYSTEM SET standby_file_management=AUTO SCOPE=BOTH SID='*';

ALTER SYSTEM SET dg_broker_config_file1=
  '/var/opt/oracle/dbaas_acfs/dgpdb1/dg_config_file/dr1dgpdb1.dat'
  SCOPE=BOTH SID='*';

ALTER SYSTEM SET dg_broker_config_file2=
  '/var/opt/oracle/dbaas_acfs/dgpdb1/dg_config_file/dr2dgpdb1.dat'
  SCOPE=BOTH SID='*';

ALTER SYSTEM SET dg_broker_start=TRUE SCOPE=BOTH SID='*';
```

### 1.2 Configure Oracle Net Connectivity on Every Cluster 1 Node

On **each** Cluster 1 node that can run an instance of `dgpdb1`, with the `dgpdb1` environment set, add a connect descriptor for `dgpdb2` to the applicable `tnsnames.ora` file.

```text
dgpdb2 =
  (DESCRIPTION =
    (ADDRESS =
      (PROTOCOL = TCP)
      (HOST = <cluster-2-scan-name>)
      (PORT = 1521)
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = <dgpdb2-service-name>)
    )
  )
```

Verify local and remote connectivity:

```shell
tnsping dgpdb1
tnsping dgpdb2
```

### 1.3 Configure the Client Password Wallet on Cluster 1

On **every** Cluster 1 node, configure `sqlnet.ora` to locate the client wallet used for administrative connections. The example uses a wallet on shared ACFS storage:

```text
WALLET_LOCATION=
  (SOURCE=
    (METHOD=file)
    (METHOD_DATA=
      (DIRECTORY=/var/opt/oracle/dbaas_acfs/dgpdb1/wallets/client)
    )
  )
SQLNET.WALLET_OVERRIDE=TRUE
```

Create the wallet once in the shared location and add credentials for both DGPDB CDBs:

```shell
WLTLOC=/var/opt/oracle/dbaas_acfs/dgpdb1/wallets/client
mkdir -p "$WLTLOC"

mkstore -wrl "$WLTLOC" -create
mkstore -wrl "$WLTLOC" -createCredential dgpdb1 sys
mkstore -wrl "$WLTLOC" -createCredential dgpdb2 sys
```

Enter the wallet password and database credentials when prompted. Use secure secrets that comply with your organization’s password-management requirements.

Verify wallet-based connectivity and inspect the available TDE keys:

```sql
connect /@dgpdb1 as SYSDBA
SELECT key_id, creator_dbname, creator_pdbname, key_use
FROM v$encryption_keys;

connect /@dgpdb2 as SYSDBA
SELECT key_id, creator_dbname, creator_pdbname, key_use
FROM v$encryption_keys;
```

On another Cluster 1 node, verify that the same Oracle Net configuration is available and that both connections succeed. Also record the PDB identifiers:

```sql
SELECT name, con_id, dbid, guid FROM v$pdbs;
```

### 1.4 Restart the `dgpdb1` RAC Instances

Restart each `dgpdb1` instance so that the instances use the updated Oracle Net wallet configuration:

```shell
srvctl stop instance -db dgpdb1 -instance dgpdb11 -force
srvctl start instance -db dgpdb1 -instance dgpdb11

srvctl stop instance -db dgpdb1 -instance dgpdb12 -force
srvctl start instance -db dgpdb1 -instance dgpdb12
```

Adapt the instance names to your environment and restart the instances in an order that meets your availability requirements.

## 2. Prepare the DGPDB CDB on Cluster 2

Repeat the equivalent preparation on Cluster 2 with the Oracle environment for `dgpdb2` set.

### 2.1 Configure Broker and File Management Parameters

```shell
mkdir -p /var/opt/oracle/dbaas_acfs/dgpdb2/dg_config_file
```

```sql
SELECT flashback_on, force_logging FROM v$database;
SHOW PARAMETER standby_file_management
SHOW PARAMETER dg_broker

ALTER SYSTEM SET standby_file_management=AUTO SCOPE=BOTH SID='*';

ALTER SYSTEM SET dg_broker_config_file1=
  '/var/opt/oracle/dbaas_acfs/dgpdb2/dg_config_file/dr1dgpdb2.dat'
  SCOPE=BOTH SID='*';

ALTER SYSTEM SET dg_broker_config_file2=
  '/var/opt/oracle/dbaas_acfs/dgpdb2/dg_config_file/dr2dgpdb2.dat'
  SCOPE=BOTH SID='*';

ALTER SYSTEM SET dg_broker_start=TRUE SCOPE=BOTH SID='*';
```

### 2.2 Configure Oracle Net Connectivity on Every Cluster 2 Node

Add a connect descriptor for `dgpdb1` to the applicable `tnsnames.ora` file on **every** Cluster 2 node:

```text
dgpdb1 =
  (DESCRIPTION =
    (ADDRESS =
      (PROTOCOL = TCP)
      (HOST = <cluster-1-scan-name>)
      (PORT = 1521)
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = <dgpdb1-service-name>)
    )
  )
```

Verify connectivity:

```shell
tnsping dgpdb2
tnsping dgpdb1
```

### 2.3 Configure the Client Password Wallet on Cluster 2

Add the following wallet configuration to the applicable `sqlnet.ora` file on **every** Cluster 2 node:

```text
WALLET_LOCATION=
  (SOURCE=
    (METHOD=file)
    (METHOD_DATA=
      (DIRECTORY=/var/opt/oracle/dbaas_acfs/dgpdb2/wallets/client)
    )
  )
SQLNET.WALLET_OVERRIDE=TRUE
```

Create the shared client wallet and store credentials for both CDBs:

```shell
WLTLOC=/var/opt/oracle/dbaas_acfs/dgpdb2/wallets/client
mkdir -p "$WLTLOC"

mkstore -wrl "$WLTLOC" -create
mkstore -wrl "$WLTLOC" -createCredential dgpdb2 sys
mkstore -wrl "$WLTLOC" -createCredential dgpdb1 sys
```

Verify connectivity, TDE keys, and PDB identifiers from both Cluster 2 nodes:

```sql
SELECT key_id, creator_dbname, creator_pdbname, key_use
FROM v$encryption_keys;

SELECT name, con_id, dbid, guid
FROM v$pdbs;
```

### 2.4 Restart the `dgpdb2` RAC Instances

```shell
srvctl stop instance -db dgpdb2 -instance dgpdb21 -force
srvctl start instance -db dgpdb2 -instance dgpdb21

srvctl stop instance -db dgpdb2 -instance dgpdb22 -force
srvctl start instance -db dgpdb2 -instance dgpdb22
```

## 3. Create and Prepare the DGPDB Broker Configuration

Run the following commands from either cluster with wallet-based Oracle Net connectivity to both CDBs.

Start DGMGRL and create one configuration for each CDB:

```text
DGMGRL> CONNECT /@dgpdb1
DGMGRL> CREATE CONFIGURATION dgpdb1 CONNECT IDENTIFIER IS dgpdb1;

DGMGRL> CONNECT /@dgpdb2
DGMGRL> CREATE CONFIGURATION dgpdb2 CONNECT IDENTIFIER IS dgpdb2;
```

Connect to `dgpdb1`, associate the second configuration, enable all configurations, and prepare them for DGPDB:

```text
DGMGRL> CONNECT /@dgpdb1
DGMGRL> ADD CONFIGURATION dgpdb2 CONNECT IDENTIFIER IS dgpdb2;
DGMGRL> ENABLE CONFIGURATION ALL;
DGMGRL> SHOW CONFIGURATION;
DGMGRL> EDIT CONFIGURATION PREPARE DGPDB;
```

Enter the requested credentials when prompted (these are NEW passwords).

Verify the PDBs known to Broker at both CDBs:

```text
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb1;
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb2;
```

Also verify the current PDB inventory directly in both CDBs:

```sql
SHOW PDBS
```

## 4. Optional: Configure and Validate the DGPDB Environment with Existing PDBs

This section configures and validates the DGPDB environment using the existing `PDB1` and `PDB2` PDBs. Skip the entire section if your DGPDB environment has no existing PDBs and you will start directly by migrating PDBs from the existing Data Guard configuration.

### 4.1 Exchange TDE Keys Between the DGPDB CDBs

Each peer CDB must have the TDE keys required to recover the source redo and the source PDB data files.
In the example, `PDB1` originates in `dgpdb1`, and `PDB2` originates in `dgpdb2`.
These keys, along with the `CDB$ROOT` keys, must be exchanged across the peer CDBs.

If Oracle Key Vault or another centralized key-management solution is used, adapt this procedure to that architecture.

#### 4.1.1 Export the `dgpdb1` Root and `PDB1` Keys

On Cluster 1, with the `dgpdb1` environment set:

```sql
ADMINISTER KEY MANAGEMENT EXPORT KEYS
  WITH SECRET "<export-secret>"
  TO '/tmp/dgpdb1_PDB1.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>"
  WITH IDENTIFIER IN (
    SELECT key_id
    FROM v$encryption_keys
    WHERE con_id IN (
      SELECT con_id
      FROM v$containers
      WHERE name IN ('CDB$ROOT', 'PDB1')
    )
  );
```

Restrict access to the exported file while permitting the approved transfer mechanism to read it. Do not use broadly permissive file modes in production.

#### 4.1.2 Export the `dgpdb2` Root and `PDB2` Keys

On Cluster 2, with the `dgpdb2` environment set:

```sql
ADMINISTER KEY MANAGEMENT EXPORT KEYS
  WITH SECRET "<export-secret>"
  TO '/tmp/dgpdb2_PDB2.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>"
  WITH IDENTIFIER IN (
    SELECT key_id
    FROM v$encryption_keys
    WHERE con_id IN (
      SELECT con_id
      FROM v$containers
      WHERE name IN ('CDB$ROOT', 'PDB2')
    )
  );
```

#### 4.1.3 Transfer the Exported Key Files

Using an approved secure transfer method:

- Copy `/tmp/dgpdb1_PDB1.wlt` to a node on Cluster 2.
- Copy `/tmp/dgpdb2_PDB2.wlt` to a node on Cluster 1.
- Set ownership and permissions so that the Oracle software owner can read each file.
- Remove intermediate copies after successful import according to your security policy.

#### 4.1.4 Import the Peer Keys

On Cluster 1, with the `dgpdb1` environment set, import the keys from `dgpdb2`:

```sql
ADMINISTER KEY MANAGEMENT IMPORT KEYS
  WITH SECRET "<export-secret>"
  FROM '/tmp/dgpdb2_PDB2.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>"
  WITH BACKUP;
```

On Cluster 2, with the `dgpdb2` environment set, import the keys from `dgpdb21:

```sql
ADMINISTER KEY MANAGEMENT IMPORT KEYS
  WITH SECRET "<export-secret>"
  FROM '/tmp/dgpdb1_PDB1.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>"
  WITH BACKUP;
```

### 4.2 Add the target PDBs and validate the configuration

#### 4.2.1 Add the target PDBs

From DGMGRL, add `PDB1` to `dgpdb2`, using `PDB1` in `dgpdb1` as its source:

```text
DGMGRL> CONNECT /@dgpdb2
DGMGRL> ADD PLUGGABLE DATABASE PDB1 AT dgpdb2
  SOURCE IS PDB1 AT dgpdb1
  PDBFILENAMECONVERT IS "'/dgpdb1/','/dgpdb2/'"
  'KEYSTORE IDENTIFIED BY "<keystore-password>"';
```


Add `PDB2` to `dgpdb1`, using `PDB2` in `dgpdb2` as its source:

```text
DGMGRL> CONNECT /@dgpdb1
DGMGRL> ADD PLUGGABLE DATABASE PDB2 AT dgpdb1
  SOURCE IS PDB2 AT dgpdb2
  PDBFILENAMECONVERT IS "'/dgpdb2/','/dgpdb1/'"
  'KEYSTORE IDENTIFIED BY "<keystore-password>"';
```

By default, in 23.26.2.0.0 and later, the source datafiles are automatically copied and renamed on the target.

#### 4.2.2 Enable Apply

```text
DGMGRL> EDIT PLUGGABLE DATABASE PDB1 AT dgpdb2 SET STATE='APPLY-ON';
DGMGRL> EDIT PLUGGABLE DATABASE PDB2 AT dgpdb1 SET STATE='APPLY-ON';
```

#### 4.2.3 Validate Broker and Database State

```text
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb1;
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb2;
DGMGRL> SHOW PLUGGABLE DATABASE PDB1 AT dgpdb1;
DGMGRL> SHOW PLUGGABLE DATABASE PDB1 AT dgpdb2;
DGMGRL> SHOW PLUGGABLE DATABASE PDB2 AT dgpdb2;
DGMGRL> SHOW PLUGGABLE DATABASE PDB2 AT dgpdb1;
```

In both CDBs, check for plug-in errors, Data Guard processes, and per-PDB statistics:

```sql
SHOW PDBS

SELECT name, cause, type, message, status
FROM pdb_plug_in_violations
WHERE type='ERROR'
  AND status <> 'RESOLVED';

SELECT p.pdb_id,
       p.pdb_name,
       pr.name,
       pr.role,
       pr.action,
       pr.sequence#,
       pr.block#,
       pr.block_count,
       pr.con_id,
       pr.inst_id
FROM gv$dataguard_process pr,
     cdb_pdbs p
WHERE pr.con_id=p.pdb_id;

SELECT p.pdb_id,
       p.pdb_name,
       p.status,
       dg.name,
       dg.value,
       dg.inst_id
FROM gv$dataguard_stats dg,
     cdb_pdbs p
WHERE dg.con_id=p.pdb_id
ORDER BY p.pdb_id, dg.inst_id;
```

#### 4.2.4 Test PDB Switchovers

Validate and switch to `PDB2` at `dgpdb1`:

```text
DGMGRL> SET TIME ON;
DGMGRL> VALIDATE PLUGGABLE DATABASE PDB2 AT dgpdb1;
DGMGRL> SWITCHOVER TO PLUGGABLE DATABASE PDB2 AT dgpdb1;
```

Validate and switch to `PDB1` at `dgpdb2`:

```text
DGMGRL> VALIDATE PLUGGABLE DATABASE PDB1 AT dgpdb2;
DGMGRL> SWITCHOVER TO PLUGGABLE DATABASE PDB1 AT dgpdb2;
```

Verify both CDBs after each switchover:

```text
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb1;
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb2;
```

The previous steps should have successfully validated the switchover at the PDB level between the two peer CDBs.

## 5. Capture the Existing Target Data File Names for `MYPDB`

In this step we start the conversion steps of `MYPDB` from a conventional Data Guard to a DGPDB configuration.

Before removing `MYPDB` from the conventional Data Guard configuration, record the target-side data file names. These files will be reused by the target PDB in `dgpdb2` so a full copy isn't required.

On Cluster 2, with the environment for the conventional Data Guard standby database set, connect as `SYSDBA` and run:

```sql
ALTER SESSION SET CONTAINER=MYPDB;

SPOOL /home/oracle/MYPDB_datafiles.lst

SELECT f.con_id,
       t.name,
       f.rfile#,
       f.ts#,
       f.name
FROM v$datafile f
JOIN v$tablespace t
  ON f.ts#=t.ts#
 AND f.con_id=t.con_id
JOIN v$pdbs p
  ON p.con_id=t.con_id
WHERE p.name='MYPDB';

SPOOL OFF
```

Retain this file for the manual data file remapping in a later step.

## 6. Export and Distribute the `MYPDB` TDE Keys

### 6.1 Export the Keys from the Conventional Data Guard Primary Database

On Cluster 1, with the environment for the conventional Data Guard primary database set, connect as `SYSDBA`:

```sql
ALTER SESSION SET CONTAINER=MYPDB;

ADMINISTER KEY MANAGEMENT EXPORT KEYS
  WITH SECRET "<export-secret>"
  TO '/tmp/dgcdb_MYPDB.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>";
```

Secure the file for transfer. Avoid world-readable permissions in production.

### 6.2 Transfer the Key File to Cluster 2

Using an approved secure transfer method:

- Make the exported key file available to `dgpdb1` on Cluster 1. In this playbook, this is the same host.
- Copy the same key file to a node on Cluster 2 so it is available to `dgpdb2`.
- Set ownership and restrictive permissions for the Oracle software owner.
- Verify checksums before importing.

## 7. Unplug `MYPDB` from the Conventional Data Guard Primary Database

Perform the following actions on Cluster 1 with the environment for the conventional Data Guard primary database set.

### 7.1 Close the PDB on All RAC Instances

```sql
ALTER PLUGGABLE DATABASE MYPDB CLOSE IMMEDIATE INSTANCES=ALL;
```

### 7.2 Create the PDB Manifest

Write the PDB metadata to a manifest file on storage that is accessible when the PDB is created in `dgpdb1`:

```sql
ALTER PLUGGABLE DATABASE MYPDB
  UNPLUG INTO '/home/oracle/MYPDB.xml';
```

### 7.3 Drop the PDB but Retain the Data Files

```sql
SHOW PDBS

DROP PLUGGABLE DATABASE MYPDB KEEP DATAFILES;
```

> **Caution:** Do not omit `KEEP DATAFILES`. The source data files are reused when the PDB is plugged into `dgpdb1` with `NOCOPY`.

## 8. Create the Source PDB in `dgpdb1`

On Cluster 1, set the environment for `dgpdb1` and connect as `SYSDBA`.

### 8.1 Import the PDB Keys into the CDB Root

```sql
ADMINISTER KEY MANAGEMENT IMPORT KEYS
  WITH SECRET "<export-secret>"
  FROM '/tmp/dgcdb_MYPDB.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>"
  WITH BACKUP;
```

### 8.2 Create the PDB Without Copying Data Files

```sql
CREATE PLUGGABLE DATABASE MYPDB
  USING '/home/oracle/MYPDB.xml'
  NOCOPY
  KEYSTORE IDENTIFIED BY "<keystore-password>";
```

### 8.3 Open the PDB and Import Its Keys

```sql
ALTER SESSION SET CONTAINER=MYPDB;

ADMINISTER KEY MANAGEMENT IMPORT KEYS
  WITH SECRET "<export-secret>"
  FROM '/tmp/dgcdb_MYPDB.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>"
  WITH BACKUP;

ALTER PLUGGABLE DATABASE MYPDB OPEN INSTANCES=ALL;
```

Check for unresolved plug-in errors:

```sql
SELECT name, cause, type, message, status
FROM pdb_plug_in_violations
WHERE type='ERROR'
  AND status <> 'RESOLVED';
```

Do not continue until all relevant errors are understood and resolved.

## 9. Add the Target PDB in `dgpdb2`

On Cluster 2, set the environment for `dgpdb2`.

### 9.1 Import the PDB Keys into `dgpdb2`

```sql
ADMINISTER KEY MANAGEMENT IMPORT KEYS
  WITH SECRET "<export-secret>"
  FROM '/tmp/dgcdb_MYPDB.wlt'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>"
  WITH BACKUP;
```

### 9.2 Add the Target PDB with `NOCOPY`

Start DGMGRL and add `MYPDB` to `dgpdb2`, using the PDB in `dgpdb1` as the source:

```text
DGMGRL> CONNECT /@dgpdb2
DGMGRL> ADD PLUGGABLE DATABASE MYPDB AT dgpdb2
  SOURCE IS MYPDB AT dgpdb1
  NOCOPY
  'KEYSTORE IDENTIFIED BY "<keystore-password>"';
```

The reference procedure deliberately omits `PDBFILENAMECONVERT` because the existing target-side data files are reused and their names are remapped manually.

## 10. Remap the Target PDB Data Files

The target PDB metadata initially references the source-side file names. Rename each file in the target PDB so that it points to the corresponding existing data file captured from the conventional Data Guard standby database.

### 10.1 Display the Current File Names

On Cluster 2, with the environment for `dgpdb2` set:

```sql
SELECT f.con_id,
       t.name,
       f.rfile#,
       f.ts#,
       f.name
FROM v$datafile f
JOIN v$tablespace t
  ON f.ts#=t.ts#
 AND f.con_id=t.con_id
JOIN v$pdbs p
  ON p.con_id=t.con_id
WHERE p.name='MYPDB';
```

### 10.2 Identify the Existing Target Files

Use `/home/oracle/MYPDB_datafiles.lst` captured earlier. On Exascale-based systems, you can also enumerate files in the appropriate vault using the supported Exascale administration tools and wallet. The exact command and vault identifier are environment-specific.

Match each source-side file to the corresponding existing target-side file by PDB GUID, tablespace, relative file number, and file purpose. Review the mapping carefully before changing any file name.

### 10.3 Rename Each Data File

With the `dgpdb2` environment set, connect as `SYSDBA`, switch to `MYPDB`, and rename every data file:

```sql
ALTER SESSION SET CONTAINER=MYPDB;

ALTER DATABASE RENAME FILE
  '<source-side-file-name>'
TO
  '<existing-target-side-file-name>';

-- Repeat the rename operation for every data file in the PDB
```

Repeat for every data file belonging to the PDB, including all RAC undo tablespaces and application tablespaces.

> **Caution:** The data file mapping is environment-specific. Do not copy the Exascale file names from the reference demo. An incorrect mapping can make the target PDB unusable or associate it with the wrong files.

## 11. Enable Apply for `MYPDB`

On Cluster 2, use DGMGRL to enable apply for the target PDB:

```text
DGMGRL> CONNECT /@dgpdb2
DGMGRL> EDIT PLUGGABLE DATABASE MYPDB AT dgpdb2 SET STATE='APPLY-ON';
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb2;
DGMGRL> SHOW PLUGGABLE DATABASE MYPDB AT dgpdb1;
DGMGRL> SHOW PLUGGABLE DATABASE MYPDB AT dgpdb2;
```

## 12. Open and Validate the Target PDB

On Cluster 2, with the `dgpdb2` environment set:

```sql
ALTER PLUGGABLE DATABASE MYPDB OPEN INSTANCES=ALL;
SHOW PDBS
```

Check for unresolved PDB plug-in errors:

```sql
SELECT name, cause, type, message, status
FROM pdb_plug_in_violations
WHERE type='ERROR'
  AND status <> 'RESOLVED';
```

Check the Data Guard processes associated with the PDB:

```sql
SELECT p.pdb_id,
       p.pdb_name,
       pr.name,
       pr.role,
       pr.action,
       pr.sequence#,
       pr.block#,
       pr.block_count,
       pr.con_id,
       pr.inst_id
FROM gv$dataguard_process pr,
     cdb_pdbs p
WHERE pr.con_id=p.pdb_id;
```

Check the per-PDB Data Guard statistics across the RAC instances:

```sql
SELECT p.pdb_id,
       p.pdb_name,
       p.status,
       dg.name,
       dg.value,
       dg.inst_id
FROM gv$dataguard_stats dg,
     cdb_pdbs p
WHERE dg.con_id=p.pdb_id
ORDER BY p.pdb_id, dg.inst_id;
```

Also perform application-level validation appropriate for the PDB, such as checking representative data, creating and starting services, and verifying connectivity.

## 13. Validate and Test PDB Switchovers

A switchover changes the source and target roles for `MYPDB`.

### 13.1 Switch the Source Role to the PDB in `dgpdb2`

```text
DGMGRL> CONNECT /@dgpdb1
DGMGRL> VALIDATE PLUGGABLE DATABASE MYPDB AT dgpdb2;
DGMGRL> SWITCHOVER TO PLUGGABLE DATABASE MYPDB AT dgpdb2;
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb1;
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb2;
```

After the switchover, verify that the new source PDB is open on the required RAC instances and that its services are placed correctly. Depending on service configuration, additional service management may be required.

### 13.2 Switch the Source Role Back to the PDB in `dgpdb1`

```text
DGMGRL> VALIDATE PLUGGABLE DATABASE MYPDB AT dgpdb1;
DGMGRL> SWITCHOVER TO PLUGGABLE DATABASE MYPDB AT dgpdb1;
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb1;
DGMGRL> SHOW ALL PLUGGABLE DATABASE AT dgpdb2;
```

## 14. Post-Conversion Checks

Complete the following checks before declaring the conversion complete:

- Broker reports the expected source and target roles for `MYPDB`.
- Apply is enabled and current on the target PDB.
- There are no unresolved `ERROR` entries in `PDB_PLUG_IN_VIOLATIONS`.
- The PDB is open on the intended RAC instances.
- Application services start on the correct cluster after a PDB role transition.
- TDE keys are available in both CDBs and encrypted data is accessible.
- All data files resolve to the intended storage locations.
- Application read and write tests succeed on the source PDB.
- A PDB switchover succeeds in both directions.
- Monitoring, backup, and operational runbooks have been updated for the new DGPDB protection model.
- Temporary key-export files and PDB manifest files are secured or removed according to policy.

## 15. Rollback Considerations

The exact rollback procedure depends on the point of failure. Define and test rollback steps before starting the conversion. At minimum, consider the following cases:

- **Before unplugging the PDB:** Correct the issue and continue after revalidation.
- **After unplugging but before creating the PDB in `dgpdb1`:** Re-create the PDB in the original CDB from the manifest with the retained data files, subject to your tested recovery procedure.
- **After creating the source PDB but before enabling DGPDB apply:** Remove the incomplete DGPDB target registration if required, then restore the original protection arrangement from backup or retained files.
- **After enabling DGPDB apply:** Use Broker status, database alert logs, PDB plug-in violations, and the saved data file maps to determine whether to repair the configuration or restore the original environment.

Do not improvise a rollback in production. Use a prevalidated procedure that accounts for TDE keys, PDB metadata, RAC services, and both copies of every data file.

## 16. Security Notes

- Do not place clear-text passwords in shell history, SQL scripts, or published documentation.
- Use a secure secrets-management solution or interactive prompts where possible.
- Protect exported TDE key files in transit and at rest.
- Use restrictive ownership and permissions rather than the permissive modes used for convenience in demonstrations.
- Remove exported key files as soon as they are no longer required and retain only the backups mandated by your key-management policy.
- Review all wallet and keystore operations with your security and database administration teams.
