---# tmux-demo-runner variablesFile=vars.json.nogit
---#
---# Prepare the two independent RAC CDBs from terraform-stacks/exaxs-rac-dgpdb
---# for DGPDB. This playbook configures Broker, Oracle Net, client wallets,
---# and PREPARE DGPDB. It does not migrate a PDB from conventional Data Guard.
---# --------------------------------------- CONNECTIONS AND WINDOW SETUP
--- tmux set-option pane-border-status bottom
--- tmux split-window -h
--- tmux select-pane -t :.0
--- tmux split-window -v
--- tmux select-pane -t :.2
--- tmux split-window -v
--- tmux select-pane -t :.0
--- tmux select-pane -T "Cluster A node 1"
ssh {{public_key}} opc@{{clu1.host1.public_ip}}
--- tmux select-pane -t :.1
--- tmux select-pane -T "Cluster A node 2"
ssh {{public_key}} opc@{{clu1.host2.public_ip}}
--- tmux select-pane -t :.2
--- tmux select-pane -T "Cluster B node 1"
ssh {{public_key}} opc@{{clu2.host1.public_ip}}
--- tmux select-pane -t :.3
--- tmux select-pane -T "Cluster B node 2"
ssh {{public_key}} opc@{{clu2.host2.public_ip}}

---# --------------------------------------- INSTALL HELPER COMMANDS
--- tmux set-option synchronize-panes on
region=$(curl -H "Authorization: Bearer Oracle" -s  -L http://169.254.169.254/opc/v2/instance | grep \"region\" | awk '{print $2}' | awk -F\" '{print $2}')
echo $region
sudo tee /etc/yum.repos.d/ol8-epel.repo <<EOF
[ol8_developer_EPEL]
name= Oracle Linux \$releasever EPEL (\$basearch)
baseurl=https://yum-$region.oracle.com/repo/OracleLinux/OL\$releasever/developer/EPEL/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF
sudo tee /etc/yum.repos.d/ol8.repo <<EOF
[ol8_UEKR7]
name=Latest Unbreakable Enterprise Kernel Release 7 for Oracle Linux \$releasever (\$basearch)
baseurl=http://yum-$region.oracle.com/repo/OracleLinux/OL\$releasever/UEKR7/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1

[ol8_latest]
name=Oracle Linux $releasever Latest (\$basearch)
baseurl=http://yum-$region.oracle.com/repo/OracleLinux/OL\$releasever/baseos/latest/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1

[ol8_appstream]
name=Oracle Linux $releasever Appstream (\$basearch)
baseurl=http://yum-$region.oracle.com/repo/OracleLinux/OL\$releasever/appstream/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF

sudo dnf install -y rlwrap git
sudo su - oracle
git clone https://github.com/ludovicocaldara/COE.git
echo ". ~/COE/profile.sh" >> $HOME/.bash_profile
. ~/.bash_profile
exit
--- tmux set-option synchronize-panes on
sudo su - oracle
--- tmux set-option synchronize-panes off

---# --------------------------------------- CLUSTER A DATABASE PREPARATION
--- tmux select-pane -t :.0
sid {{clu1.dgpdb.dbun}}
mkdir -p /var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/dg_config_file/
sql / as sysdba
select log_mode, flashback_on, force_logging from v$database;
show parameter dg_broker
alter system set standby_file_management = AUTO scope=both sid='*';
alter system set dg_broker_config_file1 = '/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/dg_config_file/dr1{{clu1.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_config_file2 = '/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/dg_config_file/dr2{{clu1.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_start = TRUE scope=both sid='*';
exit

---# --------------------------------------- CLUSTER B DATABASE PREPARATION
--- tmux select-pane -t :.2
sid {{clu2.dgpdb.dbun}}
mkdir -p /var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/dg_config_file/
sql / as sysdba
select log_mode, flashback_on, force_logging from v$database;
show parameter dg_broker
alter system set standby_file_management = AUTO scope=both sid='*';
alter system set dg_broker_config_file1 = '/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/dg_config_file/dr1{{clu2.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_config_file2 = '/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/dg_config_file/dr2{{clu2.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_start = TRUE scope=both sid='*';
exit

---# --------------------------------------- ORACLE NET: CLUSTER A NODE 1
--- tmux select-pane -t :.0
cat $TNS_ADMIN/tnsnames.ora
cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu2.dgpdb.dbun}} = (DESCRIPTION =
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu2.scan_dns_name}})(PORT = 1521))
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu2.dgpdb.dbun}}.{{clu2.domain}}))
)
EOF
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF

---# --------------------------------------- ORACLE NET: CLUSTER A NODE 2
--- tmux select-pane -t :.1
sid {{clu1.dgpdb.dbun}}
cat $TNS_ADMIN/tnsnames.ora
cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu2.dgpdb.dbun}} = (DESCRIPTION =
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu2.scan_dns_name}})(PORT = 1521))
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu2.dgpdb.dbun}}.{{clu2.domain}}))
)
EOF
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF

---# --------------------------------------- ORACLE NET: CLUSTER B NODE 1
--- tmux select-pane -t :.2
cat $TNS_ADMIN/tnsnames.ora
cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu1.dgpdb.dbun}} = (DESCRIPTION =
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu1.scan_dns_name}})(PORT = 1521))
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu1.dgpdb.dbun}}.{{clu1.domain}}))
)
EOF
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF

---# --------------------------------------- ORACLE NET: CLUSTER B NODE 2
--- tmux select-pane -t :.3
sid {{clu2.dgpdb.dbun}}
cat $TNS_ADMIN/tnsnames.ora
cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu1.dgpdb.dbun}} = (DESCRIPTION =
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu1.scan_dns_name}})(PORT = 1521))
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu1.dgpdb.dbun}}.{{clu1.domain}}))
)
EOF
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF

---# --------------------------------------- CREATE CLUSTER A CLIENT WALLET
--- tmux select-pane -t :.0
WLTLOC=/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/wallets/client
mkdir -p "$WLTLOC"
mkstore -wrl "$WLTLOC" -create
{{input:password}}
{{input:password}}
mkstore -wrl "$WLTLOC" -createCredential {{clu1.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}
mkstore -wrl "$WLTLOC" -createCredential {{clu2.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}

---# --------------------------------------- CREATE CLUSTER B CLIENT WALLET
--- tmux select-pane -t :.2
WLTLOC=/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/wallets/client
mkdir -p "$WLTLOC"
mkstore -wrl "$WLTLOC" -create
{{input:password}}
{{input:password}}
mkstore -wrl "$WLTLOC" -createCredential {{clu2.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}
mkstore -wrl "$WLTLOC" -createCredential {{clu1.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}

---# --------------------------------------- VERIFY CONNECTIVITY AND WALLETS
--- tmux select-pane -t :.0
tnsping {{clu1.dgpdb.dbun}}
tnsping {{clu2.dgpdb.dbun}}
sql /@{{clu1.dgpdb.dbun}} as sysdba
select name, db_unique_name, open_mode from v$database;
connect /@{{clu2.dgpdb.dbun}} as sysdba
select name, db_unique_name, open_mode from v$database;
exit
--- tmux select-pane -t :.2
tnsping {{clu2.dgpdb.dbun}}
tnsping {{clu1.dgpdb.dbun}}
sql /@{{clu2.dgpdb.dbun}} as sysdba
select name, db_unique_name, open_mode from v$database;
connect /@{{clu1.dgpdb.dbun}} as sysdba
select name, db_unique_name, open_mode from v$database;
exit

---# --------------------------------------- RESTART BOTH RAC DATABASES
--- tmux select-pane -t :.0
srvctl stop database -db {{clu1.dgpdb.dbun}} -stopoption immediate
srvctl start database -db {{clu1.dgpdb.dbun}}
--- tmux select-pane -t :.2
srvctl stop database -db {{clu2.dgpdb.dbun}} -stopoption immediate
srvctl start database -db {{clu2.dgpdb.dbun}}

---# --------------------------------------- CREATE AND PREPARE DGPDB
--- tmux select-pane -t :.0
dgmgrl /@{{clu1.dgpdb.dbun}}
CREATE CONFIGURATION {{clu1.dgpdb.dbun}} CONNECT IDENTIFIER IS {{clu1.dgpdb.dbun}};
connect /@{{clu2.dgpdb.dbun}}
CREATE CONFIGURATION {{clu2.dgpdb.dbun}} CONNECT IDENTIFIER IS {{clu2.dgpdb.dbun}};
connect /@{{clu1.dgpdb.dbun}}
ADD CONFIGURATION {{clu2.dgpdb.dbun}} CONNECT IDENTIFIER IS {{clu2.dgpdb.dbun}};
enable configuration all;
show configuration;
edit configuration prepare dgpdb;
{{input:password}}
{{input:password}}
show all pluggable database at {{clu1.dgpdb.dbun}};
show all pluggable database at {{clu2.dgpdb.dbun}};
exit

---# --------------------------------------- VERIFY THE PREPARED DATABASES
sql /@{{clu1.dgpdb.dbun}} as sysdba
show pdbs;
select con_id, name, con_uid, guid from v$pdbs;
connect /@{{clu2.dgpdb.dbun}} as sysdba
show pdbs;
select con_id, name, con_uid, guid from v$pdbs;
exit

echo {{clu1.dgpdb.pdb_name}}
echo {{clu2.dgpdb.pdb_name}}

---# ======================================= CREATE THE DGPDB STANDBYS
---# Cluster A starts with {{clu1.dgpdb.pdb_name}}; Cluster B starts with {{clu2.dgpdb.pdb_name}}.
---# The corresponding target PDB name must not already exist in the target CDB.
---# Copy TDE keys in both directions before adding either standby PDB.

---# --------------------------------------- VERIFY SOURCE PDBS ARE OPEN
--- tmux select-pane -t :.0
sql /@{{clu1.dgpdb.dbun}} as sysdba
select name, open_mode from v$pdbs where name in (upper('{{clu1.dgpdb.pdb_name}}'), upper('{{clu2.dgpdb.pdb_name}}'));
select name, cause, type, message, status from pdb_plug_in_violations where type = 'ERROR' and status != 'RESOLVED';
exit

--- tmux select-pane -t :.2
sql /@{{clu2.dgpdb.dbun}} as sysdba
select name, open_mode from v$pdbs where name in (upper('{{clu1.dgpdb.pdb_name}}'), upper('{{clu2.dgpdb.pdb_name}}'));
select name, cause, type, message, status from pdb_plug_in_violations where type = 'ERROR' and status != 'RESOLVED';
exit

---# --------------------------------------- EXPORT CLUSTER A ROOT AND PDB TDE KEYS
---# Verify keystore_mode is UNITED. Record root/PDB key IDs and compare them with the peer after import.
--- tmux select-pane -t :.0
sid {{clu1.dgpdb.dbun}}
sql / as sysdba
show con_name
select con_id, status, wallet_type, keystore_mode from v$encryption_wallet order by con_id;
select con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys where con_id = 1 order by activation_time;
ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  TO '/tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}";
ALTER SESSION SET CONTAINER = {{clu1.dgpdb.pdb_name}};
show con_name
select con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys order by activation_time;
ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  TO '/tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}";
ALTER SESSION SET CONTAINER = CDB$ROOT;
exit
test -s /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 && ls -l /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12
test -s /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12 && ls -l /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12
chmod 644 /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12

---# --------------------------------------- EXPORT CLUSTER B ROOT AND PDB TDE KEYS
--- tmux select-pane -t :.2
sid {{clu2.dgpdb.dbun}}
sql / as sysdba
show con_name
select con_id, status, wallet_type, keystore_mode from v$encryption_wallet order by con_id;
select con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys where con_id = 1 order by activation_time;
ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  TO '/tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}";
ALTER SESSION SET CONTAINER = {{clu2.dgpdb.pdb_name}};
show con_name
select con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys order by activation_time;
ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  TO '/tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}";
ALTER SESSION SET CONTAINER = CDB$ROOT;
exit
test -s /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 && ls -l /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12
test -s /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12 && ls -l /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12
chmod 644 /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12

---# --------------------------------------- COPY ENCRYPTED ROOT AND PDB KEY EXPORTS
--- tmux select-pane -t :.1
exit
exit
scp {{public_key}} opc@{{clu1.host1.public_ip}}:/tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 /tmp
scp {{public_key}} opc@{{clu1.host1.public_ip}}:/tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12 /tmp
scp {{public_key}} opc@{{clu2.host1.public_ip}}:/tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 /tmp
scp {{public_key}} opc@{{clu2.host1.public_ip}}:/tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12 /tmp
scp {{public_key}} /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12 opc@{{clu2.host1.public_ip}}:/tmp
scp {{public_key}} /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12 opc@{{clu1.host1.public_ip}}:/tmp
ssh {{public_key}} opc@{{clu2.host1.public_ip}} sudo chown oracle:dba /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12 && echo OK
ssh {{public_key}} opc@{{clu1.host1.public_ip}} sudo chown oracle:dba /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12 && echo OK
rm /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12
rm /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12
ssh {{public_key}} opc@{{clu1.host2.public_ip}}
sudo su - oracle

---# --------------------------------------- IMPORT CLUSTER B ROOT AND PDB KEYS INTO A
---# Import both scopes into the CDB's united keystore before creating the standby PDB.
--- tmux select-pane -t :.0
sid {{clu1.dgpdb.dbun}}
sql / as sysdba
show con_name
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  FROM '/tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" WITH BACKUP;
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  FROM '/tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" WITH BACKUP;
select con_id, status, wallet_type, keystore_mode from v$encryption_wallet order by con_id;
select con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys order by creator_dbname, creator_pdbname, activation_time;
exit

---# --------------------------------------- IMPORT CLUSTER A ROOT AND PDB KEYS INTO B
--- tmux select-pane -t :.2
sid {{clu2.dgpdb.dbun}}
sql / as sysdba
show con_name
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  FROM '/tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" WITH BACKUP;
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  FROM '/tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" WITH BACKUP;
select con_id, status, wallet_type, keystore_mode from v$encryption_wallet order by con_id;
select con_id, key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys order by creator_dbname, creator_pdbname, activation_time;
exit

---# --------------------------------------- ADD BOTH DGPDB TARGET PDBS
---# The default db_version is 23.26.3; Broker automatically instantiates target PDB files at 23.26.2+.
--- tmux select-pane -t :.0
dgmgrl /@{{clu2.dgpdb.dbun}}
ADD PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}} SOURCE IS {{clu1.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}}
  PDBFileNameConvert IS "'/{{clu1.dgpdb.dbun}}/','/{{clu2.dgpdb.dbun}}/'"
  'keystore identified by "{{input:password}}"';
connect /@{{clu1.dgpdb.dbun}}
ADD PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}} SOURCE IS {{clu2.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}}
  PDBFileNameConvert IS "'/{{clu2.dgpdb.dbun}}/','/{{clu1.dgpdb.dbun}}/'"
  'keystore identified by "{{input:password}}"';
SHOW CONFIGURATION;
SHOW PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
exit

---# --------------------------------------- IMPORT PDB KEYS IN THE STANDBY PDB CONTEXTS
---# Oracle requires a second import inside each PDB to associate its keys with that PDB.
--- tmux select-pane -t :.0
sql /@{{clu2.dgpdb.dbun}} as sysdba
alter session set container = {{clu1.dgpdb.pdb_name}};
show con_name
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  FROM '/tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" WITH BACKUP;
select key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys order by activation_time;
alter session set container = CDB$ROOT;
exit
--- tmux select-pane -t :.2
sql /@{{clu1.dgpdb.dbun}} as sysdba
alter session set container = {{clu2.dgpdb.pdb_name}};
show con_name
ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET "{{input:password}}"
  FROM '/tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12'
  FORCE KEYSTORE IDENTIFIED BY "{{input:password}}" WITH BACKUP;
select key_id, creator_dbname, creator_pdbname, key_use, activation_time from v$encryption_keys order by activation_time;
alter session set container = CDB$ROOT;
exit

---# --------------------------------------- REMOVE REMOTE KEY EXPORT FILES
--- tmux select-pane -t :.0
rm -f /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12
--- tmux select-pane -t :.2
rm -f /tmp/{{clu1.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_root_tdekeys.p12 /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}_tdekeys.p12

---# --------------------------------------- ENABLE REDO APPLY FOR BOTH STANDBY PDBS
---# Compare PDB key IDs with export output; also confirm imported root IDs in the CDB-root queries above.
--- tmux select-pane -t :.0
dgmgrl /@{{clu1.dgpdb.dbun}}
EDIT PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}} SET STATE='APPLY-ON';
EDIT PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}} SET STATE='APPLY-ON';
SHOW CONFIGURATION;
exit

---# --------------------------------------- GENERATE REDO AND VERIFY APPLY
--- tmux select-pane -t :.0
sid {{clu1.dgpdb.dbun}}
sql / as sysdba
ALTER SYSTEM ARCHIVE LOG CURRENT;
ALTER SYSTEM ARCHIVE LOG CURRENT;
exit
--- tmux select-pane -t :.2
sid {{clu2.dgpdb.dbun}}
sql / as sysdba
ALTER SYSTEM ARCHIVE LOG CURRENT;
ALTER SYSTEM ARCHIVE LOG CURRENT;
exit
--- tmux select-pane -t :.0
dgmgrl /@{{clu1.dgpdb.dbun}}
SHOW PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
VALIDATE PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
VALIDATE PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
exit

---# --------------------------------------- VERIFY PLUG-IN ERRORS AND RAC OPEN MODES
--- tmux select-pane -t :.0
sql /@{{clu1.dgpdb.dbun}} as sysdba
select inst_id, name, open_mode from gv$pdbs where name in (upper('{{clu1.dgpdb.pdb_name}}'), upper('{{clu2.dgpdb.pdb_name}}')) order by name, inst_id;
select name, cause, type, message, status from pdb_plug_in_violations where type = 'ERROR' and status != 'RESOLVED';
connect /@{{clu2.dgpdb.dbun}} as sysdba
select inst_id, name, open_mode from gv$pdbs where name in (upper('{{clu1.dgpdb.pdb_name}}'), upper('{{clu2.dgpdb.pdb_name}}')) order by name, inst_id;
select name, cause, type, message, status from pdb_plug_in_violations where type = 'ERROR' and status != 'RESOLVED';
exit

---# --------------------------------------- SWITCH OVER CLUSTER B PDB TO A
---# Proceed only after VALIDATE reports Ready for Switchover and target apply is running.
--- tmux select-pane -t :.0
dg_ /@{{clu1.dgpdb.dbun}}
SET TIME ON
VALIDATE PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
SWITCHOVER TO PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};

---# --------------------------------------- SWITCH OVER CLUSTER A PDB TO B
VALIDATE PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
SWITCHOVER TO PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}};
SHOW PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}};
exit

---# --------------------------------------- VERIFY THE FINAL PDB ROLES ON RAC
--- tmux select-pane -t :.0
sql /@{{clu1.dgpdb.dbun}} as sysdba
select inst_id, name, open_mode from gv$pdbs where name in (upper('{{clu1.dgpdb.pdb_name}}'), upper('{{clu2.dgpdb.pdb_name}}')) order by name, inst_id;
select name, cause, type, message, status from pdb_plug_in_violations where type = 'ERROR' and status != 'RESOLVED';
connect /@{{clu2.dgpdb.dbun}} as sysdba
select inst_id, name, open_mode from gv$pdbs where name in (upper('{{clu1.dgpdb.pdb_name}}'), upper('{{clu2.dgpdb.pdb_name}}')) order by name, inst_id;
select name, cause, type, message, status from pdb_plug_in_violations where type = 'ERROR' and status != 'RESOLVED';
exit

---# --------------------------------------- CREATE ROLE-BASED PDB SERVICES
---# After the switchovers above, PDB1 is primary on Cluster B and PDB2 is primary on Cluster A.
---# Register both role services for each PDB on both CDBs so they are available after a later switchover.
---# The stack uses the default SID prefix (DB_NAME), so the two RAC instances are DB_NAME1 and DB_NAME2.
--- tmux select-pane -t :.0
sid {{clu1.dgpdb.dbun}}
srvctl add service -db {{clu1.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_rw -pdb {{clu1.dgpdb.pdb_name}} -role PRIMARY -policy AUTOMATIC -preferred {{clu1.dgpdb.dbname}}1,{{clu1.dgpdb.dbname}}2
srvctl add service -db {{clu1.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_ro -pdb {{clu1.dgpdb.pdb_name}} -role PHYSICAL_STANDBY -policy AUTOMATIC -preferred {{clu1.dgpdb.dbname}}1 -available {{clu1.dgpdb.dbname}}2
srvctl add service -db {{clu1.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_rw -pdb {{clu2.dgpdb.pdb_name}} -role PRIMARY -policy AUTOMATIC -preferred {{clu1.dgpdb.dbname}}1,{{clu1.dgpdb.dbname}}2
srvctl add service -db {{clu1.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_ro -pdb {{clu2.dgpdb.pdb_name}} -role PHYSICAL_STANDBY -policy AUTOMATIC -preferred {{clu1.dgpdb.dbname}}1 -available {{clu1.dgpdb.dbname}}2
--- tmux select-pane -t :.2
sid {{clu2.dgpdb.dbun}}
srvctl add service -db {{clu2.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_rw -pdb {{clu1.dgpdb.pdb_name}} -role PRIMARY -policy AUTOMATIC -preferred {{clu2.dgpdb.dbname}}1,{{clu2.dgpdb.dbname}}2
srvctl add service -db {{clu2.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_ro -pdb {{clu1.dgpdb.pdb_name}} -role PHYSICAL_STANDBY -policy AUTOMATIC -preferred {{clu2.dgpdb.dbname}}1,{{clu2.dgpdb.dbname}}2
srvctl add service -db {{clu2.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_rw -pdb {{clu2.dgpdb.pdb_name}} -role PRIMARY -policy AUTOMATIC -preferred {{clu2.dgpdb.dbname}}1,{{clu2.dgpdb.dbname}}2
srvctl add service -db {{clu2.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_ro -pdb {{clu2.dgpdb.pdb_name}} -role PHYSICAL_STANDBY -policy AUTOMATIC -preferred {{clu2.dgpdb.dbname}}1,{{clu2.dgpdb.dbname}}2

---# --------------------------------------- START SERVICES FOR THE CURRENT PDB ROLES
---# Cluster A: PDB1 is standby and PDB2 is primary.
--- tmux select-pane -t :.0
srvctl start service -db {{clu1.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_rw
---# start and stop the RO on primary to create it
srvctl start service -db {{clu1.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_ro
srvctl stop service -db {{clu1.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_ro
srvctl start service -db {{clu1.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_ro
srvctl stop service -db {{clu1.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_ro

---# Cluster B: PDB1 is primary and PDB2 is standby.
--- tmux select-pane -t :.2
srvctl start service -db {{clu2.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_rw
---# start and stop the RO on primary to create it
srvctl start service -db {{clu2.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_ro
srvctl stop service -db {{clu2.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_ro
srvctl start service -db {{clu2.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_ro
srvctl stop service -db {{clu2.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_ro

--- tmux select-pane -t :.0
srvctl start service -db {{clu1.dgpdb.dbun}} -service {{clu1.dgpdb.pdb_name}}_ro
srvctl status service -db {{clu1.dgpdb.dbun}}
--- tmux select-pane -t :.2
srvctl start service -db {{clu2.dgpdb.dbun}} -service {{clu2.dgpdb.pdb_name}}_ro
srvctl status service -db {{clu2.dgpdb.dbun}}