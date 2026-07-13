# Command Mapping: tmux Demo to Customer Playbook

## Purpose

This appendix maps the operational blocks in `exaxs-dg-to-dgpdb.rendered` to the customer-facing playbook, `convert-existing-pdb-to-dgpdb.md`.

It is intended for technical review. It records the execution location, database environment, treatment of the original commands, and important adaptations made while removing tmux, SSH, Git, `rlwrap`, and COE dependencies.

## Topology Interpretation

| Demo panes | Physical location | Database environments used |
|---|---|---|
| Pane 0 | Cluster 1, node 1 | `dgpdb1`; conventional Data Guard primary `dgcdb` |
| Pane 1 | Cluster 1, node 2 | `dgpdb1`; temporary file-transfer shell in the demo |
| Pane 2 | Cluster 2, node 1 | `dgpdb2`; conventional Data Guard standby `dgcdb` |
| Pane 3 | Cluster 2, node 2 | `dgpdb2`; Exascale file inspection in the demo |

The customer playbook replaces pane references with explicit cluster and database-environment instructions.

## Terminology Adaptations

| Demo wording or implication | Customer playbook wording |
|---|---|
| Primary or standby DGPDB database | Not used |
| Primary or standby DGPDB host | Not used |
| DGPDB source side | Source PDB in a named CDB |
| DGPDB standby side | Target PDB in a named CDB |
| Host 1 or pane 0 | Cluster 1, with the specified database environment set |
| Host 2 or pane 2 | Cluster 2, with the specified database environment set |
| `sid <database>` | Set the Oracle environment for `<database>` |
| SCP and SSH sequences | Transfer the file by an approved secure method |

## Block-by-Block Mapping

| Original block | Execution context | Playbook section | Treatment and review notes |
|---|---|---|---|
| Introductory comments | N/A | About This Playbook; Scope | Rewritten to describe two RAC clusters that host both DGPDB CDBs and the members of the conventional Data Guard configuration. Corrected DGPDB terminology so roles apply to PDBs, not CDBs. |
| Connections and tmux window setup | All four nodes | Omitted | SSH commands, pane creation, pane titles, and pane selection are demo-only mechanics. |
| YUM, Git, `rlwrap`, and COE setup | All nodes | Omitted | Explicitly excluded by request. No dependency on `sid`, `sql`, or `u` helper functions remains. |
| Cluster 1 DGPDB host preparation | Cluster 1, `dgpdb1` | Section 1 | Retained Broker parameter configuration, shared Broker file paths, Oracle Net configuration, wallet setup, key inspection, and RAC instance restarts. Converted `sid dgpdb1` to an environment prerequisite. |
| Cluster 1 second-node checks | Cluster 1, second RAC node, `dgpdb1` | Sections 1.2 and 1.3 | Retained as an instruction to apply and verify Oracle Net configuration on every RAC node. Removed duplicate command listings where the action is identical. |
| Cluster 2 DGPDB host preparation | Cluster 2, `dgpdb2` | Section 2 | Retained symmetrically with Cluster 1. |
| Cluster 2 second-node checks | Cluster 2, second RAC node, `dgpdb2` | Sections 2.2 and 2.3 | Retained as all-node configuration and verification guidance. |
| Create two Broker configurations | Any host with connectivity to both CDBs | Section 3 | Retained command order: create `dgpdb1` configuration, create `dgpdb2` configuration, add the second configuration, enable all, prepare DGPDB, and verify PDBs. |
| Export keys for `PDB1` and `PDB2` | Cluster 1 `dgpdb1`; Cluster 2 `dgpdb2` | Section 4.1 | Retained key selection for `CDB$ROOT` and the applicable PDB. Replaced literal secrets with placeholders and added security cautions. This configuration and validation section is optional. |
| Copy peer key files | Between clusters | Section 4.1.3 | Replaced SCP, SSH, temporary local copies, and permissive modes with an approved secure transfer procedure. Execution order is unchanged: export, transfer, import. |
| Import peer keys | Cluster 1 `dgpdb1`; Cluster 2 `dgpdb2` | Section 4.1.4 | Retained. |
| Add `PDB1` and `PDB2` | DGMGRL connected to both CDBs | Section 4.2.1 | Retained as part of the optional environment-configuration and validation section. Preserved the `PDBFILENAMECONVERT` examples. |
| Enable apply for `PDB1` and `PDB2` | DGMGRL | Section 4.2.2 | Retained. |
| Show PDB state and query Data Guard views | Both DGPDB CDBs | Section 4.2.3 | Retained and formatted for documentation. |
| Switch `PDB1` and `PDB2` | DGMGRL | Section 4.2.4 | Retained as optional validation. Reworded to identify the CDB containing the new source PDB rather than using CDB-level primary terminology. |
| Save `MYPDB` data file list | Cluster 2, conventional Data Guard standby `dgcdb` | Section 5 | Retained before any destructive operation. This is essential for later target-side manual file remapping. |
| Export `MYPDB` TDE keys | Cluster 1, conventional Data Guard primary `dgcdb` | Section 6.1 | Retained. File name simplified in documentation. Literal passwords removed. |
| Copy `MYPDB` key file | Cluster 1 to Cluster 2 | Section 6.2 | Replaced SSH and SCP mechanics with secure-transfer guidance. Added checksum recommendation. |
| Close `MYPDB` | Cluster 1, conventional Data Guard primary `dgcdb` | Section 7.1 | Retained with `INSTANCES=ALL` because the source database is RAC. |
| Unplug `MYPDB` | Cluster 1, conventional Data Guard primary `dgcdb` | Section 7.2 | Retained. Manifest location must be accessible for the subsequent create operation. |
| Drop `MYPDB KEEP DATAFILES` | Cluster 1, conventional Data Guard primary `dgcdb` | Section 7.3 | Retained and highlighted as a caution. |
| Import keys into `dgpdb1` root | Cluster 1, `dgpdb1` | Section 8.1 | Retained before creating the PDB. |
| Create `MYPDB` in `dgpdb1` with `NOCOPY` | Cluster 1, `dgpdb1` | Section 8.2 | Retained. The PDB uses the source-side files retained from the conventional Data Guard primary database. |
| Open `MYPDB`, import keys in the PDB, close and reopen | Cluster 1, `dgpdb1` | Section 8.3 | Retained in the original order. Added a mandatory plug-in violation review. |
| Import keys into `dgpdb2` | Cluster 2, `dgpdb2` | Section 9.1 | Retained before adding the target PDB. |
| Add `MYPDB` at `dgpdb2` with `NOCOPY` | Cluster 2, DGMGRL | Section 9.2 | Retained. The demo comment that `PDBFILENAMECONVERT` “doesn't work” was not presented as a product fact. The playbook states only that it is deliberately omitted to reuse and manually map existing target files. |
| Query target file names | Cluster 2, `dgpdb2` | Section 10.1 | Retained. |
| Enumerate Exascale files | Cluster 2, privileged OS account | Section 10.2 | Generalized. The exact `xsh` vault identifier and wallet path are deployment-specific and unsuitable for a customer-copyable command. |
| Manual `ALTER DATABASE RENAME FILE` statements | Cluster 2, `dgpdb2`, container `MYPDB` | Section 10.3 | Retained as a parameterized pattern instead of publishing demo-specific Exascale object names. The required order remains: identify mapping, review it, then rename every PDB file. |
| Enable apply for `MYPDB` | Cluster 2, DGMGRL | Section 11 | Retained. |
| Open `MYPDB` and query status views | Cluster 2, `dgpdb2` | Section 12 | Retained. Added application-level validation guidance. |
| Validate and switch `MYPDB` to `dgpdb2` | DGMGRL | Section 13.1 | Retained. Described as moving the source role to the PDB in `dgpdb2`. |
| Validate and switch `MYPDB` back to `dgpdb1` | DGMGRL | Section 13.2 | Retained. |

## Preserved Execution Order for the Conversion

The customer playbook preserves the following critical sequence from the demo:

1. Record the existing target-side PDB data files from the conventional Data Guard standby database.
2. Export the PDB TDE keys from the conventional Data Guard primary database.
3. Transfer the key file to both DGPDB environments as required.
4. Close the PDB on all RAC instances of the conventional Data Guard primary database.
5. Unplug the PDB to a manifest.
6. Drop the PDB while retaining its data files.
7. Import the keys into `dgpdb1`.
8. Create the PDB in `dgpdb1` with `NOCOPY`.
9. Open the PDB, import its keys in the PDB container, and reopen it.
10. Import the keys into `dgpdb2`.
11. Add the target PDB in `dgpdb2` with `NOCOPY`.
12. Match and rename every target-side data file.
13. Enable apply for the target PDB.
14. Open and validate the target PDB.
15. Validate and test switchovers in both directions.

## Items Intentionally Not Carried Forward

- tmux pane setup and navigation
- SSH connection commands and private-key paths
- Git repository cloning
- YUM repository creation
- `rlwrap` installation
- COE installation and helper commands
- Literal IP addresses, SCAN names, service names, passwords, Exascale vault IDs, PDB GUIDs, and file object names
- Broad `chmod 644` guidance for exported TDE key material

## Reviewer Checklist

- Confirm the database unique names and RAC instance names in the customer environment.
- Confirm the Broker command syntax against the exact Oracle AI Database 26ai release update used by the customer.
- Confirm that the PDB manifest path is accessible when `CREATE PLUGGABLE DATABASE` is executed in `dgpdb1`.
- Confirm that every source-side data file has one unambiguous target-side match.
- Confirm that all RAC undo and application tablespace files are included.
- Confirm that the TDE key export includes every key required to read the PDB data.
- Confirm the application service behavior after each PDB switchover.
- Confirm that the rollback procedure has been tested with the same storage and keystore architecture.
