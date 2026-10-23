---
description: "Prepare two Oracle RAC container databases for bidirectional Data Guard protection of selected PDBs, validate redo apply, perform planned PDB switchovers, and configure application services."
keywords: "Oracle Data Guard, DG PDB, DGPDB, Oracle RAC, Data Guard Broker, TDE"
---

# Playbook: Configure Bidirectional Data Guard for PDBs on Oracle RAC {#GUID-D8320FEB-4EA9-4996-B6A8-1867EC40B7E9}

Prepare two Oracle RAC container databases for bidirectional Data Guard protection of selected PDBs, validate redo apply, and perform controlled PDB switchovers.

## Purpose and scope {#GUID-53AE4EB4-A4E3-4FDB-9C83-17F59F279DA7}

This playbook configures Data Guard for Pluggable Databases (DG PDB) between two existing, independent Oracle RAC container databases (CDBs). Each CDB remains a primary database. The broker protects selected PDBs between them and can switch a protected PDB's role without switching the whole CDB.

This is not a procedure for creating a conventional CDB-level physical standby, migrating a PDB, or performing a failover. Use the Oracle documentation for those operations and for release-specific requirements.

The example uses two directions so each CDB begins with one source PDB and receives a standby copy of the peer's PDB. Replace every example name, path, host, service, and credential placeholder with values approved for the customer environment. Never reuse credentials from the terminal logs.

## Example topology {#GUID-2212F285-847B-43ED-A11F-39F3A06E9493}

| Direction | Source CDB and PDB | Target CDB and PDB | Initial source role |
| --- | --- | --- | --- |
| A to B | `<cdb-a>` / `<pdb-a>` | `<cdb-b>` / `<pdb-a>` | Primary on CDB A |
| B to A | `<cdb-b>` / `<pdb-b>` | `<cdb-a>` / `<pdb-b>` | Primary on CDB B |
{: summary="Map each source PDB to its target CDB and initial primary role."}

After setup, each CDB contains one primary PDB and one physical standby PDB. The example later switches `<pdb-b>` to CDB A and back to CDB B. It does not switch `<pdb-a>`.

## Before you begin {#GUID-EFD3A4A7-C917-40A8-BA84-010177C65B53}

Confirm the following for both CDBs before changing the broker configuration:

- Both CDBs exist, use an SPFILE, run in `ARCHIVELOG` mode, and can connect to one another over Oracle Net TCP/IP.
- `DG_BROKER_START` is or will be `TRUE` on every instance. Use shared broker configuration file locations that are accessible to all RAC instances in each CDB.
- `STANDBY_FILE_MANAGEMENT` is set to `AUTO` on all instances, as in the tested configuration.
- The source PDBs are available and open `READ WRITE`. The target CDB does not already contain the target PDB name.
- The Oracle Database release supports the intended DG PDB workflow. The captured lab ran Oracle AI Database 26ai 23.26.3. The Oracle guide documents automatic target PDB file instantiation beginning with 23.26.2; earlier releases and `NOCOPY` workflows need the release-specific manual steps.
- If Transparent Data Encryption (TDE) is enabled, the source CDB root and each source PDB have usable master keys. The TDE keystore is open, and the PDB keystore mode meets the environment's requirements.
- You have approved SYSDBA or SYSDG access, the DGPDB_INT credentials for both CDBs, a secure method to transfer encrypted TDE key exports, and an approved maintenance window if a database restart is required by the local configuration.
- You have selected PDB datafile path mappings, Oracle Net aliases, client wallet locations, RAC instance placement, and application service names for both sites.

The Oracle guide also calls for a review of the general DGMGRL prerequisites and DG PDB concepts before applying its scenarios.

### Record environment values {#GUID-D2AEEECA-34A9-4BEE-89CE-C868501B69B0}

Complete this inventory before running commands. Use the same aliases and names consistently in Oracle Net, wallets, DGMGRL, and service configuration.

| Value | CDB A | CDB B |
| --- | --- | --- |
| `DB_UNIQUE_NAME` | `<cdb-a>` | `<cdb-b>` |
| Broker configuration name | `<config-a>` | `<config-b>` |
| Oracle Net alias | `<alias-a>` | `<alias-b>` |
| SCAN host and port | `<scan-a>:1521` | `<scan-b>:1521` |
| CDB service name | `<service-a>` | `<service-b>` |
| Source PDB | `<pdb-a>` | `<pdb-b>` |
| RAC instance names | `<instance-a1>,<instance-a2>` | `<instance-b1>,<instance-b2>` |
| Broker config file paths | `<shared-path-a>/dr1.dat`, `<shared-path-a>/dr2.dat` | `<shared-path-b>/dr1.dat`, `<shared-path-b>/dr2.dat` |
| PDB file path prefix | `<datafile-prefix-a>` | `<datafile-prefix-b>` |
{: summary="Record the database, broker, network, PDB, RAC, and file path values for each site."}

## Procedure {#GUID-A23DC8D5-450A-4373-B5BA-91816894CBC0}

The output blocks in this procedure are excerpts from the recorded Oracle AI Database 26ai lab. They show observed results, not guaranteed timings. Credentials, IP addresses, hostnames, and TDE key identifiers are omitted or anonymized.

### 1. Prepare the Oracle environment on each RAC site {#GUID-1370AEE9-28EC-45F7-9016-18133767766D}

Connect as the database software owner and select the correct CDB environment on each site. The transcript uses helper shell functions to select a CDB; use the environment-selection method supported at the customer site.

Keep Oracle Net files consistent across the RAC nodes. Store wallets and broker files on storage available to every instance when the cluster design requires shared files. Do not copy the lab's public IP addresses, SSH key path, or helper-repository setup into a customer environment.

### 2. Verify prerequisites and set broker parameters {#GUID-725A6F34-AB1A-4936-85AD-09F060E81433}

Run these checks in each CDB as SYSDBA. Record the output before changing parameters.

```sql
SELECT log_mode, flashback_on, force_logging FROM v$database;
SHOW PARAMETER spfile;
SHOW PARAMETER dg_broker;
```

The captured CDBs reported `ARCHIVELOG`, and `FORCE_LOGGING` was enabled. Treat flashback and force logging as environment and protection-policy checks; confirm the exact requirements for the customer's release and configuration.

Example output from CDB A:

```text
LOG_MODE      FLASHBACK_ON    FORCE_LOGGING
_____________ _______________ ________________
ARCHIVELOG    YES             YES
```

Set the broker file paths and parameters independently in each CDB. Use distinct paths for CDB A and CDB B. The paths must be accessible to all RAC instances.

```sql
ALTER SYSTEM SET standby_file_management = AUTO SCOPE=BOTH SID='*';
ALTER SYSTEM SET dg_broker_config_file1 = '<shared-path>/dr1<db-unique-name>.dat' SCOPE=BOTH SID='*';
ALTER SYSTEM SET dg_broker_config_file2 = '<shared-path>/dr2<db-unique-name>.dat' SCOPE=BOTH SID='*';
ALTER SYSTEM SET dg_broker_start = TRUE SCOPE=BOTH SID='*';
```

Each parameter change in the captured session returned:

```text
System altered.
```

The lab stopped and restarted both RAC databases after this preparation. That transcript does not establish that a restart is required. Confirm whether your parameter changes or Exadata service procedures require one; if so, schedule and execute it under the customer's database restart procedure.

### 3. Configure Oracle Net and client wallets {#GUID-8292206A-E175-403A-AC54-F14B70CC197F}

Add a connect descriptor for the peer CDB to `tnsnames.ora` on every node where DGMGRL or SQLcl will run. Point the descriptor to the peer's SCAN and CDB service. Add the reciprocal descriptor on the other site.

```ini
<alias-b> =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = <scan-b>)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = <service-b>)
    )
  )
```

Configure `sqlnet.ora` to use the client wallet directory for that site's Oracle environment. The directory in the lab was on shared ACFS storage.

```text
WALLET_LOCATION = (SOURCE = (METHOD = file)
  (METHOD_DATA = (DIRECTORY = <client-wallet-directory>)))
SQLNET.WALLET_OVERRIDE = TRUE
```

Create a client wallet on each site and store SYS credentials for both CDB aliases. Enter wallet and database passwords at the secure prompts; do not put them in command history or this playbook.

```bash
WLTLOC=<client-wallet-directory>
mkdir -p "$WLTLOC"
mkstore -wrl "$WLTLOC" -create
mkstore -wrl "$WLTLOC" -createCredential <alias-a> sys
mkstore -wrl "$WLTLOC" -createCredential <alias-b> sys
```

Test both local and remote aliases from each site's Oracle environment before continuing.

```bash
tnsping <alias-a>
tnsping <alias-b>
sql /@<alias-a> as sysdba
```

In SQLcl, query `v$database` and confirm that the connection reached the expected `DB_UNIQUE_NAME`. Repeat the checks from CDB B. Correct any alias or wallet error before using DGMGRL.

The captured `tnsping` calls resolved both aliases through `TNSNAMES` and returned `OK`:

```text
Used TNSNAMES adapter to resolve the alias
Attempting to contact (DESCRIPTION=... HOST=<scan-host> ... SERVICE_NAME=<cdb-service> ...)
OK (10 msec)
```

### 4. Create, connect, and prepare the broker configurations {#GUID-8E43A0CC-1A62-4C36-BB78-4D38693E7C5A}

Create one broker configuration for each primary CDB, add the peer configuration, and enable both. Use the Oracle Net aliases from the previous step.

The captured setup retained Broker's default `MaxPerformance` protection mode and asynchronous transport. Confirm that these settings meet the customer's protection and recovery objectives before enabling the configurations.

```text
dgmgrl /@<alias-a>
CREATE CONFIGURATION <config-a> CONNECT IDENTIFIER IS <alias-a>;
CONNECT /@<alias-b>
CREATE CONFIGURATION <config-b> CONNECT IDENTIFIER IS <alias-b>;
CONNECT /@<alias-a>
ADD CONFIGURATION <config-b> CONNECT IDENTIFIER IS <alias-b>;
ENABLE CONFIGURATION ALL;
SHOW CONFIGURATION;
```

Continue in DGMGRL and prepare both configurations for DG PDB. This command prompts for the DGPDB_INT password at each CDB. Enter the correct credential for each prompt.

```text
EDIT CONFIGURATION PREPARE DGPDB;
SHOW ALL PLUGGABLE DATABASE AT <alias-a>;
SHOW ALL PLUGGABLE DATABASE AT <alias-b>;
```

Confirm that `SHOW CONFIGURATION` reports `SUCCESS` and that the expected PDBs are listed. The command prepares broker structures; it does not create a CDB-level standby.

The captured run created two configurations, linked and enabled them, then prepared both CDBs:

```text
Configuration "dgpdb1_pkp_lhr" created with primary database "dgpdb1_pkp_lhr"
Configuration "dgpdb2_3x2_lhr" created with primary database "dgpdb2_3x2_lhr"
Configuration dgpdb2_3x2_lhr added.
Enabled.
Configuration Status:
SUCCESS

Enter password for DGPDB_INT account at dgpdb1_pkp_lhr:
Enter password for DGPDB_INT account at dgpdb2_3x2_lhr:
Prepared Data Guard per Pluggable Database at dgpdb2_3x2_lhr.
Prepared Data Guard per Pluggable Database at dgpdb1_pkp_lhr.
```

### 5. Confirm source and target PDB readiness {#GUID-0010F0F9-25D9-496B-A46C-A5A795302879}

Connect to each CDB as SYSDBA. Confirm that each source PDB is open `READ WRITE` and that the target PDB name is available in the peer CDB.

```sql
SELECT name, open_mode
FROM v$pdbs
WHERE name IN (UPPER('<pdb-a>'), UPPER('<pdb-b>'));

SELECT name, cause, type, message, status
FROM pdb_plug_in_violations
WHERE type = 'ERROR' AND status != 'RESOLVED';
```

Resolve relevant plug-in errors and confirm the source PDB is open before continuing. Do not add a target PDB if a PDB with that target name already exists in its CDB.

### 6. Exchange TDE keys in both directions when TDE is enabled {#GUID-55FFFEDB-72CA-46D8-90AC-272CFC67AB0D}

TDE key exchange is required when TDE protects the source CDB root or source PDB data. Export the source CDB root keys while connected to `CDB$ROOT`, then export that source PDB's keys while connected to the PDB. Repeat on both sites because the example transports redo in both directions.

The following is a template for one CDB. Use a unique export filename for the CDB root and each PDB. Enter a strong export secret and the keystore password through the approved secret-handling process.

```sql
-- Connected to the source CDB as SYSDBA in CDB$ROOT
SELECT con_id, status, wallet_type, keystore_mode
FROM v$encryption_wallet
ORDER BY con_id;

SELECT con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time
FROM v$encryption_keys
WHERE con_id = 1
ORDER BY activation_time;

ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS
  WITH SECRET "<export-secret>"
  TO '<secure-staging>/<cdb-root-export>.p12'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>";

ALTER SESSION SET CONTAINER = <source-pdb>;
SELECT con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time
FROM v$encryption_keys
ORDER BY activation_time;

ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS
  WITH SECRET "<export-secret>"
  TO '<secure-staging>/<source-pdb-export>.p12'
  FORCE KEYSTORE IDENTIFIED BY "<keystore-password>";

ALTER SESSION SET CONTAINER = CDB$ROOT;
```

Transfer the encrypted exports to the peer using an approved secure channel. Keep file permissions restrictive and make the files readable by the Oracle software owner on the destination. For example, set owner-only access on each export file:

```bash
chmod 600 <export-file>.p12
```

The lab used `chmod 644`; do not use that broad permission for customer key exports. Remove temporary files after successful import according to the site's retention and media-sanitization policy.

On the destination CDB, import the peer's root and source-PDB export files into the CDB root keystore. Use `WITH BACKUP` and verify the key IDs and keystore state after import. Repeat in the reverse direction.

```sql
-- Connected as SYSDBA to the destination CDB in CDB$ROOT
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS
  WITH SECRET "<export-secret>"
  FROM '<secure-staging>/<peer-cdb-root-export>.p12'
  FORCE KEYSTORE IDENTIFIED BY "<destination-keystore-password>" WITH BACKUP;

ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS
  WITH SECRET "<export-secret>"
  FROM '<secure-staging>/<peer-source-pdb-export>.p12'
  FORCE KEYSTORE IDENTIFIED BY "<destination-keystore-password>" WITH BACKUP;

SELECT con_id, status, wallet_type, keystore_mode
FROM v$encryption_wallet
ORDER BY con_id;

SELECT con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time
FROM v$encryption_keys
ORDER BY creator_dbname, creator_pdbname, activation_time;
```

Compare the imported root and PDB key IDs with the source export output. After the root-context imports, the transcript attempted extra imports of the source PDB exports in PDB context, including inside a newly created target PDB. Those attempts returned `ORA-46655`. The documented scenario imports the source root and PDB keys into the destination keystore before adding the target PDB. Do not repeat the extra PDB-context import unless the installed release's current TDE guidance requires it.

The successful root-context imports returned:

```text
Key MANAGEMENT succeeded.
Key MANAGEMENT succeeded.
```

The captured wallet query then showed the PDB keystores open in united mode:

```text
   CON_ID STATUS    WALLET_TYPE    KEYSTORE_MODE
_________ _________ ______________ ________________
        1 OPEN      AUTOLOGIN      NONE
        2 OPEN      AUTOLOGIN      UNITED
        3 OPEN      AUTOLOGIN      UNITED
```

An extra import in PDB context returned this output:

```text
Error report -
ORA-46655: no valid keys in the file from which keys are to be imported
```

### 7. Add the target PDBs {#GUID-CBE02CBA-EE37-4BAE-AF7E-A40C0EF6A071}

Use DGMGRL to add each target PDB on the peer CDB. The target PDB name must not already exist there. Set `PDBFileNameConvert` from the actual source datafile path prefix to the intended target path. Review the mapping carefully before execution.

```text
ADD PLUGGABLE DATABASE <pdb-a> AT <alias-b>
  SOURCE IS <pdb-a> AT <alias-a>
  PDBFileNameConvert IS "'<datafile-prefix-a>','<datafile-prefix-b>'"
  'keystore identified by "<cdb-b-keystore-password>"';

CONNECT /@<alias-a>
ADD PLUGGABLE DATABASE <pdb-b> AT <alias-a>
  SOURCE IS <pdb-b> AT <alias-b>
  PDBFileNameConvert IS "'<datafile-prefix-b>','<datafile-prefix-a>'"
  'keystore identified by "<cdb-a-keystore-password>"';

SHOW CONFIGURATION;
SHOW PLUGGABLE DATABASE <pdb-a> AT <alias-a>;
SHOW PLUGGABLE DATABASE <pdb-a> AT <alias-b>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-b>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-a>;
```

If TDE is not enabled, omit the keystore clause according to the installed release's DGMGRL syntax. On releases with automatic PDB instantiation, the broker copies target PDB datafiles. For older releases or when using `NOCOPY`, follow the matching Oracle guide for manual datafile instantiation and PDB-level standby redo logs.

The terminal reported each target PDB as added. The first add also printed a process failure message, and the immediate status showed apply was not running yet:

```text
Pluggable Database "PDB1" added
Created process to run a program, but command failed.

Data Guard Role:     Physical Standby
Intended State:      APPLY-ON
Apply State:         Not Running
Pluggable Database Status:
ORA-16914: Redo Apply Services were not running at the standby pluggable database.
```

Treat the add message and PDB status as separate checks. In this capture, the PDB was registered, but redo apply still needed to be started and verified.

### 8. Start and verify redo apply {#GUID-511C824E-32FE-4A4F-A91F-6A35AE236004}

Enable apply for both standby PDBs. Connect to DGMGRL for either configuration.

```text
EDIT PLUGGABLE DATABASE <pdb-a> AT <alias-b> SET STATE='APPLY-ON';
EDIT PLUGGABLE DATABASE <pdb-b> AT <alias-a> SET STATE='APPLY-ON';
SHOW CONFIGURATION;
```

Both `EDIT PLUGGABLE DATABASE` commands returned:

```text
Succeeded.
Succeeded.
```

Generate archived redo on each source CDB if needed to move initial changes through transport and apply. The captured run issued this command twice on each source.

```sql
ALTER SYSTEM ARCHIVE LOG CURRENT;
ALTER SYSTEM ARCHIVE LOG CURRENT;
```

Each archive command returned:

```text
System altered.
```

Check each primary and target PDB in DGMGRL. Wait for the configuration and PDB statuses to report `SUCCESS`, with apply running on each target. Validate each target and wait for `Ready for Switchover: YES` before a planned transition.

```text
SHOW PLUGGABLE DATABASE <pdb-a> AT <alias-a>;
SHOW PLUGGABLE DATABASE <pdb-a> AT <alias-b>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-b>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-a>;
VALIDATE PLUGGABLE DATABASE <pdb-a> AT <alias-b>;
VALIDATE PLUGGABLE DATABASE <pdb-b> AT <alias-a>;
```

Also confirm RAC open modes and plug-in errors on both CDBs.

Immediately after enabling apply, the first `SHOW CONFIGURATION` checks returned a transient warning. Later, after apply started and transport settled, DGMGRL reported `SUCCESS` and switchover validation passed:

```text
Warning: ORA-16910: Apply state is inconsistent for one or more standby pluggable databases.
Configuration Status:
WARNING

Configuration Status:
SUCCESS
```

```text
Pluggable database - PDB2 at dgpdb1_pkp_lhr
  Data Guard Role:     Physical Standby
  Transport Lag:       0 seconds
  Apply Lag:           0 seconds
  Intended State:      APPLY-ON
  Apply State:         Running
Pluggable Database Status:
SUCCESS

Ready for Switchover:    YES
Data Guard Role:         Physical Standby
Apply State:             Running
Standby Redo Log Files:  8
```

```sql
SELECT inst_id, name, open_mode
FROM gv$pdbs
WHERE name IN (UPPER('<pdb-a>'), UPPER('<pdb-b>'))
ORDER BY name, inst_id;

SELECT name, cause, type, message, status
FROM pdb_plug_in_violations
WHERE type = 'ERROR' AND status != 'RESOLVED';
```

The target PDB normally remains in a standby recovery state. Do not require `READ WRITE` for a physical standby PDB.

### 9. Perform a planned PDB switchover {#GUID-F8CD7838-2B77-45BA-8DE0-C25E0A2AD14F}

Before each switchover, confirm that the target PDB is reachable, apply is running, the redo lag is acceptable for the change, and `VALIDATE PLUGGABLE DATABASE` reports `Ready for Switchover: YES`. The source PDB must be open `READ WRITE`; Oracle Broker checks this during the operation.

The captured run switched `<pdb-b>` from CDB B to CDB A, then switched it back. To switch it to CDB A:

```text
VALIDATE PLUGGABLE DATABASE <pdb-b> AT <alias-a>;
SWITCHOVER TO PLUGGABLE DATABASE <pdb-b> AT <alias-a>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-a>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-b>;
```

Verify the new primary and former primary roles. Before switching the PDB back, confirm that the current primary is open `READ WRITE` on every RAC instance that must serve it. The captured second switchover failed with `ORA-16838` until the new primary PDB was opened on all instances.

If the PDB is not open on all required instances, connect to the current primary CDB as SYSDBA and open it across the RAC instances. Use this only after confirming that this CDB currently hosts the PDB in the primary role.

```sql
ALTER PLUGGABLE DATABASE <pdb-b> OPEN INSTANCES=ALL;
```

Then validate and switch back:

```text
VALIDATE PLUGGABLE DATABASE <pdb-b> AT <alias-b>;
SWITCHOVER TO PLUGGABLE DATABASE <pdb-b> AT <alias-b>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-a>;
SHOW PLUGGABLE DATABASE <pdb-b> AT <alias-b>;
```

The first switchover succeeded. The attempted return switchover failed twice with `ORA-16838`, even though validation reported `Ready for Switchover: YES`. After the current primary PDB was opened on all instances, the return switchover succeeded:

```text
Switchover succeeded, new primary is "pdb2"

Ready for Switchover:    YES
Data Guard Role:         Physical Standby
Apply State:             Running

ORA-16838: Source pluggable database is not opened in read/write mode.
Failed.

SQL> alter pluggable database pdb2 open instances=all;
Pluggable database PDB2 altered.

Switchover succeeded, new primary is "pdb2"
```

The transcript's successful round trip leaves `<pdb-a>` primary on CDB A and `<pdb-b>` primary on CDB B. It does not leave the PDB roles reversed. If the change requires moving `<pdb-a>`, perform a separate validated switchover for that PDB.

The final RAC queries showed the primary PDB open read/write on both instances and the paired standby mounted. Both CDBs returned no unresolved plug-in errors:

```text
CDB A:
INST_ID NAME    OPEN_MODE
       1 PDB1    READ WRITE
       2 PDB1    READ WRITE
       1 PDB2    MOUNTED
       2 PDB2    MOUNTED
no rows selected

CDB B:
INST_ID NAME    OPEN_MODE
       1 PDB1    MOUNTED
       2 PDB1    MOUNTED
       1 PDB2    READ WRITE
       2 PDB2    READ WRITE
no rows selected
```

### 10. Reconcile application services with the PDB roles {#GUID-60301F3A-1EA0-442A-A99A-837363E4908C}

Create Clusterware-managed services for the application PDBs, and verify their placement after every role change. The transcript's service section is not a validated automation procedure for tracking DG PDB roles.

For this topology, both CDBs remain database role `PRIMARY`. The SRVCTL service `-role` option selects a CDB database role; it does not select a DG PDB source or target role. A service registered with `-role PHYSICAL_STANDBY` will therefore not automatically follow a PDB switchover between these two primary CDBs. A manual `srvctl start service` can start a service even when its configured database role does not match.

If the customer uses operator-controlled services, define services per PDB and CDB with a manual policy and no database-role filter, then start or stop them only after checking the PDB role in DGMGRL. For example:

```bash
srvctl add service -db <cdb-a> -service <pdb-a>_rw -pdb <pdb-a> \
  -policy MANUAL -preferred <instance-a1>,<instance-a2>
```

Repeat the service definition for the peer PDB and on the peer CDB, using approved instance placement. Do not start a service solely because its name ends in `_rw` or `_ro`; first confirm the PDB role, open mode, and customer read-only licensing and service design. For automated role-aware service movement, use an architecture that observes DG PDB roles and is supported for the customer's release.

After each switchover, compare `SHOW PLUGGABLE DATABASE` output with `srvctl status service -db <cdb>`. Ensure the read/write application service runs only where the PDB is primary. A standby read-only service requires a supported read-only standby state and separate validation.

The successful round trip in the captured run ends with this PDB role map:

| PDB | CDB A | CDB B |
| --- | --- | --- |
| `<pdb-a>` | Primary; place its read/write service here | Physical standby; optional read-only service if supported |
| `<pdb-b>` | Physical standby; optional read-only service if supported | Primary; place its read/write service here |
{: summary="Expected PDB roles and service placement after the captured switchover round trip."}

For a planned PDB switchover, reconcile the read/write service after DGMGRL confirms the new primary role. With operator-controlled services, stop the service on the former primary and start it on the new primary. Build equivalent checks into restart and failure procedures when using `-policy MANUAL`.

```bash
srvctl stop service -db <former-primary-cdb> -service <pdb>_rw
srvctl start service -db <new-primary-cdb> -service <pdb>_rw
```

The final captured status matched the round-trip roles for the read/write services. One standby read-only service was running on only one RAC instance, and its start attempt on the peer produced `ORA-01153`:

```text
CDB A:
Service pdb1_ro is not running.
Service pdb1_rw is running on instances dgpdb11,dgpdb12
Service pdb2_ro is running on instances dgpdb11
Service pdb2_rw is not running.

CDB B:
Service pdb1_ro is running on instances dgpdb22
Service pdb1_rw is not running.
Service pdb2_ro is not running.
Service pdb2_rw is running on instances dgpdb21,dgpdb22

ORA-01153: An incompatible media recovery is active.
```

This output demonstrates why the runbook checks service status on every expected instance and does not treat a service start command as proof of correct placement.

## Monitoring and completion criteria {#GUID-5CA718AC-ABB5-46A7-ACFB-72DA87BCBCE9}

The configuration is ready for operational handoff when all of these checks pass:

- `SHOW CONFIGURATION` reports `SUCCESS`.
- Each protected source PDB reports `Primary`, and its paired target reports `Physical Standby` with `Intended State: APPLY-ON` and `Apply State: Running`.
- `VALIDATE PLUGGABLE DATABASE` reports `Ready for Switchover: YES` for each target before planned role changes.
- `gv$pdbs` shows the expected PDB state on all RAC instances, and the unresolved plug-in error query returns no rows.
- TDE key IDs in each destination keystore match the source root and PDB key exports, when TDE is enabled.
- Each application service is configured and running only where the customer service plan expects it.

Record the final DGMGRL output, database and PDB roles, lag, RAC open modes, TDE key verification, and service status in the customer's change record.

## Troubleshooting observations from the captured run {#GUID-9A24DC45-3D73-4A43-89A7-27E83A9ED861}

| Symptom in the logs | Interpretation and response |
| --- | --- |
| `ORA-12154` while connecting | The captured command used an alias that was not present in `tnsnames.ora`. Compare the alias with the inventory and test it with `tnsping` from the same Oracle environment. |
| `Created process to run a program, but command failed.` after `ADD PLUGGABLE DATABASE` | The target PDB was subsequently reported as added, but its first status showed apply not running. Check the broker status, alert logs, and apply state instead of treating the add message alone as success. |
| `ORA-46655: no valid keys in the file from which keys are to be imported` | The transcript shows this during extra PDB-context imports after root-context key imports, including one attempt inside a target PDB. Verify the intended import context, file path, key IDs, and keystore state before retrying. |
| `ORA-46643` naming a missing `wallet_root/tde` directory | Check the TDE wallet configuration and container context, along with the export-file path and permissions, before retrying. The captured message names the wallet directory, so do not assume the `.p12` file itself is missing. |
| `ORA-16914` immediately after adding a target PDB | The captured target PDB had not started redo apply. Set its state to `APPLY-ON`, then check broker status and transport/apply lag again. |
| `ORA-16838` during a PDB switchover | The source PDB was not open `READ WRITE`. Confirm the source/target roles and open the current primary on the required RAC instances before retrying validation and switchover. |
| `ORA-01153` during a service start | The captured log shows this during service handling while media recovery was active. Do not infer success from a later service status alone; check broker apply state, PDB role/open mode, and service placement before proceeding. |
{: summary="Relate observed Oracle errors to checks from the captured run and safe next steps."}

Treat these as observations from one lab run, not as a complete error catalog. Follow the Oracle error help and the customer's support procedures for errors that persist.

## Removing DG PDB protection {#GUID-B19119EF-7C17-489D-A47E-0108C408FEB9}

Removing a target PDB stops recovery and leaves its source PDB unprotected. Use the Oracle removal scenario as a separate, approved decommission change. Review whether target datafiles should be retained; `REMOVE DATAFILES` deletes them. Do not use these commands as a switchover or failback procedure.

```text
REMOVE PLUGGABLE DATABASE <target-pdb> AT <target-cdb>;
```

Remove associated service definitions and broker configuration links only when the decommission plan calls for them. Verify the final broker configuration and retained files after each approved removal step.

## Oracle references {#GUID-53B0143E-B1B7-490F-8B12-8281F01F7320}

- [Scenarios for Using DGMGRL with a DG PDB Configuration](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/setting-dgpdb.html)
- [Prerequisites for Using DG PDB](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/prerequisites-using-dg-pdb-23ai.html)
- [Managing Broker Configurations](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/managing-oracle-data-guard-broker-configurations.html)
- [Scenario 3: Create the Source and Target Configurations](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/scenario-3-create-source-and-target-configurations.html)
- [Scenario 4: Establish a Connection Between the Configurations and Enable Them](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/scenario-4-establish-connection-configurations-and-enable-them.html)
- [Scenario 5: Prepare the Databases for DG PDB](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/scenario-5-prepare-databases-dg-pdb.html)
- [Scenario 6: Configure Data Guard Protection for the Source PDB](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/scenario-6-configure-data-guard-protection-source-pdb.html)
- [Scenario 7: Switchover from Source PDB to Target PDB](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/scenario-7-switchover-source-pdb-target-pdb.html)
- [Performing PDB Switchover](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/performing-switchover-dg-pdbs.html)
- [SRVCTL Command Reference](https://docs.oracle.com/en/database/oracle/oracle-database/26/racad/server-control-utility-reference.html)
- [Scenario 10: Removing a DG PDB Configuration](https://docs.oracle.com/en/database/oracle/oracle-database/26/dgbkr/scenario-10-removing-dg-pdb-configuration.html)

## Applicability and adaptation {#GUID-F9B09427-7ADE-418B-9780-AB42D511FE69}

The command sequence was exercised on Exadata RAC CDBs running Oracle AI Database 26ai 23.26.3. Adapt paths, wallet configuration, instance placement, PDB names, and service policy to the customer's release and architecture. Validate the resulting configuration in a nonproduction environment before adopting it as a change procedure.
