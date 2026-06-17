---# tmux-demo-runner variablesFile=dgpdb-vars.json.nogit
--- tmux split-window -h
---# ---------------------------------------  SCENARIO 1 & 2: CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
ssh opc@{{host1.public_ip}}
sudo su - oracle
ps -eaf | grep pmon
sql / as sysdba
select flashback_on, force_logging from v$database ;
alter database flashback on;
show parameter standby_file_management
alter system set standby_file_management = AUTO;
show parameter dg_broker
alter system set dg_broker_start = TRUE;
exit
cat $ORACLE_HOME/network/admin/tnsnames.ora

cat <<EOF >> $ORACLE_HOME/network/admin/tnsnames.ora
{{host2.dbun}} = (DESCRIPTION = 
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{host2.name}}.{{host2.domain}})(PORT = 1521)) 
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{host2.dbun}}.{{host2.domain}})) 
) 
EOF

cat $ORACLE_HOME/network/admin/tnsnames.ora
tnsping {{host1.dbun}}
tnsping {{host2.dbun}}

cat $ORACLE_HOME/network/admin/sqlnet.ora
cat <<EOF >> $ORACLE_HOME/network/admin/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/opt/oracle/dcs/commonstore/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
cat $ORACLE_HOME/network/admin/sqlnet.ora

WLTLOC=/opt/oracle/dcs/commonstore/wallets/client
mkdir -p $WLTLOC
mkstore -wrl ${WLTLOC} -create
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{host1.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{host2.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}

ls -l $WLTLOC
sql /@{{host1.dbun}} as sysdba 
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
connect /@{{host2.dbun}} as sysdba
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
exit
---# ---------------------------------------  SCENARIO 1 & 2: CONNECTION TO THE SECOND HOST
--- tmux select-pane -t :.1
ssh opc@{{host2.public_ip}}
sudo su - oracle
ps -eaf | grep pmon
sql / as sysdba
select flashback_on, force_logging from v$database ;
alter database flashback on;
show parameter standby_file_management
alter system set standby_file_management = AUTO;
show parameter dg_broker
alter system set dg_broker_start = TRUE;
exit
cat $ORACLE_HOME/network/admin/tnsnames.ora

cat <<EOF >> $ORACLE_HOME/network/admin/tnsnames.ora
{{host1.dbun}} = (DESCRIPTION = 
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{host1.name}}.{{host1.domain}})(PORT = 1521)) 
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{host1.dbun}}.{{host1.domain}})) 
) 
EOF

cat $ORACLE_HOME/network/admin/tnsnames.ora
tnsping {{host1.dbun}}
tnsping {{host2.dbun}}

cat $ORACLE_HOME/network/admin/sqlnet.ora
cat <<EOF >> $ORACLE_HOME/network/admin/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/opt/oracle/dcs/commonstore/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
cat $ORACLE_HOME/network/admin/sqlnet.ora

WLTLOC=/opt/oracle/dcs/commonstore/wallets/client
mkdir -p $WLTLOC
mkstore -wrl ${WLTLOC} -create
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{host1.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{host2.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}

ls -l $WLTLOC
sql /@{{host1.dbun}} as sysdba 
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
connect /@{{host2.dbun}} as sysdba
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
exit

---# ---------------------------------------- RESTART THE CDBS TO GET THE NEW sqlnet.ora
--- tmux select-pane -t :.0
sql / as sysdba
startup force
exit
--- tmux select-pane -t :.1
sql / as sysdba
startup force
exit
---# ----------------------------------------  change GUID of one of the two PDBs as they are equal due to cloning
--- tmux select-pane -t :.1
---# save the key
sql / as sysdba
alter session set container={{host2.pdb_name}};
---# required to export the key before unplug
ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
TO '/tmp/{{host2.dbun}}_{{host2.pdb_name}}.p12' FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" ;
alter session set container=cdb$root;
---# close and unplug
ALTER PLUGGABLE DATABASE {{host2.pdb_name}} CLOSE;
ALTER PLUGGABLE DATABASE  {{host2.pdb_name}} UNPLUG INTO '/home/oracle/{{host2.pdb_name}}.xml';
DROP PLUGGABLE DATABASE {{host2.pdb_name}} KEEP DATAFILES;
---# plug with new dbid
CREATE PLUGGABLE DATABASE {{host2.pdb_name}} AS CLONE  USING '/home/oracle/{{host2.pdb_name}}.xml' NOCOPY;
ALTER  PLUGGABLE DATABASE {{host2.pdb_name}} OPEN;
ALTER  PLUGGABLE DATABASE {{host2.pdb_name}} SAVE STATE;
---# import keys and reopen
alter session set container={{host2.pdb_name}};
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
FROM '/tmp/{{host2.dbun}}_{{host2.pdb_name}}.p12' FORCE KEYSTORE IDENTIFIED BY "{{input:password}}"
WITH BACKUP USING '{{input:password}}';
---# reopen to validate
alter session set container=cdb$root;
ALTER  PLUGGABLE DATABASE {{host2.pdb_name}} CLOSE;
ALTER  PLUGGABLE DATABASE {{host2.pdb_name}} OPEN;
select key_id, creator_dbname, creator_pdbname, creator_pdbguid, activating_pdbname, activating_pdbguid from v$encryption_keys;
-- rekey so the creator PDBGUID matches
ADMINISTER KEY MANAGEMENT SET KEY FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" WITH BACKUP;
select con_id, key_id, creator_pdbguid, activating_pdbguid, tag, creation_time, activation_time from v$encryption_keys order by activation_time;
exit
---# ----------------------------------------  SCENARIO 3 AND 4: CREATING DGPDB CONFIGURATION
--- tmux select-pane -t :.0
dgmgrl /@{{host1.dbun}}
CREATE CONFIGURATION {{host1.dbun}} CONNECT IDENTIFIER IS {{host1.dbun}};
connect /@{{host2.dbun}}
CREATE CONFIGURATION {{host2.dbun}} CONNECT IDENTIFIER IS {{host2.dbun}};
connect /@{{host1.dbun}}
ADD CONFIGURATION {{host2.dbun}} CONNECT IDENTIFIER IS {{host2.dbun}}; 
enable configuration all;
show configuration;
edit configuration prepare dgpdb;
{{input:password}}
{{input:password}}
show all pluggable database at {{host1.dbun}};
show all pluggable database at {{host2.dbun}};
exit
sql /@{{host1.dbun}} as sysdba
show pdbs;
connect /@{{host2.dbun}} as sysdba
show pdbs;
exit
---# ----------------------------------------  SCENARIO 5a: EXPORT THE KEYS to import to the other CDB
--- tmux select-pane -t :.0
sql / as sysdba
administer key management export keys with secret "{{input:password}}"
  to '/tmp/{{host1.dbun}}_{{host1.pdb_name}}.wlt' force keystore identified by "{{input:password}}"
  with identifier in (
    select key_id from v$encryption_keys where con_id in (select con_id from v$containers where name in ('CDB$ROOT','{{host1.pdb_name}}'))
 );
exit
--- tmux select-pane -t :.1
sql / as sysdba
administer key management export keys with secret "{{input:password}}"
  to '/tmp/{{host2.dbun}}_{{host2.pdb_name}}.wlt' force keystore identified by "{{input:password}}"
  with identifier in (
    select key_id from v$encryption_keys where con_id in (select con_id from v$containers where name in ('CDB$ROOT','{{host2.pdb_name}}'))
 );
exit
--- tmux select-pane -t :.0
---# ------------------------------------------ TEMPORARY NEW TERMINAL FOR THE COPY OF THE KEYS
--- tmux split-window -v

---# COPYING SOURCE KEYS LOCALLY
scp opc@{{host1.public_ip}}:/tmp/{{host1.dbun}}_{{host1.pdb_name}}.wlt /tmp
scp opc@{{host2.public_ip}}:/tmp/{{host2.dbun}}_{{host2.pdb_name}}.wlt /tmp
---# COPYING KEYS TO REMOTE TARGETS
scp /tmp/{{host1.dbun}}_{{host1.pdb_name}}.wlt opc@{{host2.public_ip}}:/tmp
scp /tmp/{{host2.dbun}}_{{host2.pdb_name}}.wlt opc@{{host1.public_ip}}:/tmp
---# CHANGING PERMISSIONS
ssh opc@{{host2.public_ip}} sudo chown oracle:dba /tmp/{{host1.dbun}}_{{host1.pdb_name}}.wlt && echo OK
ssh opc@{{host1.public_ip}} sudo chown oracle:dba /tmp/{{host2.dbun}}_{{host2.pdb_name}}.wlt && echo OK
---# REMOVE LOCALLY TO CLEANUP
rm /tmp/{{host1.dbun}}_{{host1.pdb_name}}.wlt
rm /tmp/{{host2.dbun}}_{{host2.pdb_name}}.wlt
exit
---# ----------------------------------------  IMPORTING TDE KEYS
--- tmux select-pane -t :.0
sql / as sysdba
administer key management import keys with secret "{{input:password}}" from '/tmp/{{host2.dbun}}_{{host2.pdb_name}}.wlt'
 force keystore identified by "{{input:password}}" with backup;
exit
--- tmux select-pane -t :.1
sql / as sysdba
administer key management import keys with secret "{{input:password}}" from '/tmp/{{host1.dbun}}_{{host1.pdb_name}}.wlt'
 force keystore identified by "{{input:password}}" with backup;
select con_id, name, guid, to_char(creation_time,'DD-MON-YY HH24:MI:SS') as cr_date from v$containers where name = '{{host2.pdb_name}}';
exit
---# ----------------------------------------  SCENARIO 5: PREPARE THE DATABASES
--- tmux select-pane -t :.0
dgmgrl /@{{host1.dbun}}
ADD PLUGGABLE DATABASE {{host1.pdb_name}} AT {{host2.dbun}} SOURCE IS {{host1.pdb_name}} AT {{host1.dbun}} 
  pdbfilenameconvert is "'/{{host1.dbun}}/','/{{host2.dbun}}/'"
  'keystore identified by "{{input:password}}"';
ADD PLUGGABLE DATABASE {{host2.pdb_name}} AT {{host1.dbun}} SOURCE IS {{host2.pdb_name}} AT {{host2.dbun}} 
  pdbfilenameconvert is "'/{{host2.dbun}}/','/{{host1.dbun}}/'"
  'keystore identified by "{{input:password}}"';
---# ----------------------------------------- START THE APPLY
edit pluggable database {{host1.pdb_name}} at {{host2.dbun}} set state='APPLY-ON';
edit pluggable database {{host2.pdb_name}} at {{host1.dbun}} set state='APPLY-ON';

show all pluggable database at {{host1.dbun}}
show all pluggable database at {{host2.dbun}}
show pluggable database {{host1.pdb_name}} at {{host1.dbun}}
show pluggable database {{host1.pdb_name}} at {{host2.dbun}}
show pluggable database {{host2.pdb_name}} at {{host2.dbun}}
show pluggable database {{host2.pdb_name}} at {{host1.dbun}}
exit


--- tmux select-pane -t :.0
sql /@{{host1.dbun}} as sysdba
show pdbs
select name, cause, type, message, status from PDB_PLUG_IN_VIOLATIONS where type = 'ERROR' and status != 'RESOLVED';
select p.pdb_id, p.pdb_name, pr.name, pr.role,  pr.action, pr.sequence#, pr.block# , pr.block_count, pr.con_id, pr.inst_id  from gv$dataguard_process pr, cdb_pdbs p where pr.con_id=p.pdb_id;
select p.pdb_id, p.pdb_name, p.status, dg.name, dg.value, dg.inst_id from gv$dataguard_stats dg, cdb_pdbs p where dg.con_id=p.pdb_id order by p.pdb_id, dg.inst_id;
connect /@{{host2.dbun}} as sysdba
show pdbs
select name, cause, type, message, status from PDB_PLUG_IN_VIOLATIONS where type = 'ERROR' and status != 'RESOLVED';
select p.pdb_id, p.pdb_name, pr.name, pr.role,  pr.action, pr.sequence#, pr.block# , pr.block_count, pr.con_id, pr.inst_id  from gv$dataguard_process pr, cdb_pdbs p where pr.con_id=p.pdb_id;
select p.pdb_id, p.pdb_name, p.status, dg.name, dg.value, dg.inst_id from gv$dataguard_stats dg, cdb_pdbs p where dg.con_id=p.pdb_id order by p.pdb_id, dg.inst_id;
exit

---# ----------------------------------------  SCENARIO 7: SWITCHOVER
dgmgrl /@{{host1.dbun}}
set time on
validate pluggable database {{host2.pdb_name}} at {{host1.dbun}};
switchover to pluggable database {{host2.pdb_name}} at {{host1.dbun}};
show all pluggable database at {{host1.dbun}}
show all pluggable database at {{host2.dbun}}
validate pluggable database {{host1.pdb_name}} at {{host2.dbun}};
switchover to pluggable database {{host1.pdb_name}} at {{host2.dbun}};
show all pluggable database at {{host1.dbun}}
show all pluggable database at {{host2.dbun}}
exit