---# tmux-demo-runner variablesFile=vars.json.nogit
---#
---# The goal of this (rather long!) playbook is to demonstrate the setup of DGPDB between
---# two standalone RAC ExaDB-XS, then the migration of a PDB from a regular Data Guard
---# to the DGPDB environment.
---# The playbook assumes there are a DG Group with regular Data Guard and two standalone RAC
---# ExaDB-XS databases running on the same two clusters (one standalone per cluster, and the 
---# primary and standby running each on a different cluster).
---#
---# Such a stack can be created using the terraform stack dg_exaxs-rac-cplane
---# 
---# --------------------------------------- CONNECTIONS AND WINDOW SETUP
--- tmux set-option pane-border-status bottom
--- tmux split-window -h
--- tmux select-pane -t :.0 
--- tmux select-pane -T {{clu1.host1.name}}
ssh {{public_key}} opc@{{clu1.host1.public_ip}} 
--- tmux split-window -v
--- tmux select-pane -t :.1 
--- tmux select-pane -T {{clu1.host2.name}}
ssh {{public_key}} opc@{{clu1.host2.public_ip}} 
--- tmux select-pane -t :.2 
--- tmux select-pane -T {{clu2.host1.name}}
ssh {{public_key}} opc@{{clu2.host1.public_ip}} 
--- tmux split-window -v
--- tmux select-pane -t :.3 
--- tmux select-pane -T {{clu2.host2.name}}
ssh {{public_key}} opc@{{clu2.host2.public_ip}} 

---# --------------------------------------- SETUP YUM, GIT, AND COE
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
u
exit
--- tmux set-option synchronize-panes on
sudo su - oracle
--- tmux set-option synchronize-panes off

---# ------------------------------ DGPDB SETUP
---# ------------------------------ HOST PREPARATION - CLUSTER 1
--- tmux select-pane -t :.0 
sid {{clu1.dgpdb.dbun}}
mkdir /var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/dg_config_file/
sql / as sysdba
select flashback_on, force_logging from v$database ;
show parameter standby_file_management
alter system set standby_file_management = AUTO scope=both sid='*';
show parameter dg_broker
---# the dg config files must go on shared storage
alter system set dg_broker_config_file1 = '/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/dg_config_file/dr1{{clu1.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_config_file2 = '/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/dg_config_file/dr2{{clu1.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_start = TRUE scope=both sid='*';
exit
---# add the connection strings
cat $TNS_ADMIN/tnsnames.ora
cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu2.dgpdb.dbun}} = (DESCRIPTION = 
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu2.scan_name}}.{{clu2.domain}})(PORT = 1521)) 
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu2.dgpdb.dbun}}.{{clu2.domain}})) 
) 
EOF

tnsping {{clu1.dgpdb.dbun}}
tnsping {{clu2.dgpdb.dbun}}

---# modify sqlnet.ora to find the password wallet
cat $TNS_ADMIN/sqlnet.ora
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
cat $TNS_ADMIN/sqlnet.ora

---# create the password wallet
WLTLOC=/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/wallets/client
mkdir -p $WLTLOC
mkstore -wrl ${WLTLOC} -create
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{clu1.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{clu2.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}
---# check what's in there in the DB encryption keys (for TDE, later)
ls -l $WLTLOC
sql /@{{clu1.dgpdb.dbun}} as sysdba 
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
connect /@{{clu2.dgpdb.dbun}} as sysdba
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
exit
---# ---------------------------------------  SCENARIO 1 & 2: CONNECTION TO THE SECOND HOST (SAME CLUSTER)
---# the steps for the second host are the same
--- tmux select-pane -t :.1
sid {{clu1.dgpdb.dbun}}
sql / as sysdba
select flashback_on, force_logging from v$database ;
show parameter standby_file_management
show parameter dg_broker_start
exit
cat $TNS_ADMIN/tnsnames.ora

cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu2.dgpdb.dbun}} = (DESCRIPTION = 
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu2.scan_name}}.{{clu2.domain}})(PORT = 1521)) 
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu2.dgpdb.dbun}}.{{clu2.domain}})) 
) 
EOF

tnsping {{clu1.dgpdb.dbun}}
tnsping {{clu2.dgpdb.dbun}}

cat $TNS_ADMIN/sqlnet.ora
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu1.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
cat $TNS_ADMIN/sqlnet.ora

sql /@{{clu1.dgpdb.dbun}} as sysdba 
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
select name, con_id, dbid, guid from v$pdbs; 
connect /@{{clu2.dgpdb.dbun}} as sysdba
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
select name, con_id, dbid, guid from v$pdbs; 
exit


---# ---------------------------------------- RESTART THE CDBS TO GET THE NEW sqlnet.ora
---# once the config is OK, we restart everything to get the new wallet
--- tmux select-pane -t :.0
srvctl stop instance -db {{clu1.dgpdb.dbun}} -instance {{clu1.dgpdb.inst1}} -force
srvctl start instance -db {{clu1.dgpdb.dbun}} -instance {{clu1.dgpdb.inst1}} 
srvctl stop instance -db {{clu1.dgpdb.dbun}} -instance {{clu1.dgpdb.inst2}} -force
srvctl start instance -db {{clu1.dgpdb.dbun}} -instance {{clu1.dgpdb.inst2}} 

---# ------------------------------ HOST PREPARATION - CLUSTER 2
---# second cluster: same as the first cluster
--- tmux select-pane -t :.2 
sid {{clu2.dgpdb.dbun}}
mkdir /var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/dg_config_file/
sql / as sysdba
select flashback_on, force_logging from v$database ;
show parameter standby_file_management
alter system set standby_file_management = AUTO scope=both sid='*';
show parameter dg_broker
alter system set dg_broker_config_file1 = '/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/dg_config_file/dr1{{clu2.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_config_file2 = '/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/dg_config_file/dr2{{clu2.dgpdb.dbname}}.dat' scope=both sid='*';
alter system set dg_broker_start = TRUE scope=both sid='*';
exit
cat $TNS_ADMIN/tnsnames.ora

cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu1.dgpdb.dbun}} = (DESCRIPTION = 
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu1.scan_name}}.{{clu1.domain}})(PORT = 1521)) 
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu1.dgpdb.dbun}}.{{clu1.domain}})) 
) 
EOF

tnsping {{clu2.dgpdb.dbun}}
tnsping {{clu1.dgpdb.dbun}}

cat $TNS_ADMIN/sqlnet.ora
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
cat $TNS_ADMIN/sqlnet.ora

WLTLOC=/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/wallets/client
mkdir -p $WLTLOC
mkstore -wrl ${WLTLOC} -create
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{clu2.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}
mkstore -wrl ${WLTLOC} -createCredential {{clu1.dgpdb.dbun}} sys
{{input:password}}
{{input:password}}
{{input:password}}

ls -l $WLTLOC
sql /@{{clu2.dgpdb.dbun}} as sysdba 
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
connect /@{{clu1.dgpdb.dbun}} as sysdba
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
exit
---# ---------------------------------------  SCENARIO 1 & 2: CONNECTION TO THE SECOND HOST (SAME CLUSTER)
--- tmux select-pane -t :.3
sid {{clu2.dgpdb.dbun}}
sql / as sysdba
select flashback_on, force_logging from v$database ;
show parameter standby_file_management
show parameter dg_broker_start
exit
cat $TNS_ADMIN/tnsnames.ora

cat <<EOF >> $TNS_ADMIN/tnsnames.ora
{{clu1.dgpdb.dbun}} = (DESCRIPTION = 
 (ADDRESS = (PROTOCOL = TCP)(HOST = {{clu1.scan_name}}.{{clu1.domain}})(PORT = 1521)) 
 (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = {{clu1.dgpdb.dbun}}.{{clu1.domain}})) 
) 
EOF

tnsping {{clu2.dgpdb.dbun}}
tnsping {{clu1.dgpdb.dbun}}

cat $TNS_ADMIN/sqlnet.ora
cat <<EOF >> $TNS_ADMIN/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)
      (METHOD_DATA= (DIRECTORY=/var/opt/oracle/dbaas_acfs/{{clu2.dgpdb.dbname}}/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
cat $TNS_ADMIN/sqlnet.ora

sql /@{{clu2.dgpdb.dbun}} as sysdba 
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
select name, con_id, dbid, guid from v$pdbs; 
connect /@{{clu1.dgpdb.dbun}} as sysdba
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
select name, con_id, dbid, guid from v$pdbs; 
exit


---# ---------------------------------------- RESTART THE CDBS TO GET THE NEW sqlnet.ora
--- tmux select-pane -t :.2
srvctl stop instance -db {{clu2.dgpdb.dbun}} -instance {{clu2.dgpdb.inst1}} -force
srvctl start instance -db {{clu2.dgpdb.dbun}} -instance {{clu2.dgpdb.inst1}} 
srvctl stop instance -db {{clu2.dgpdb.dbun}} -instance {{clu2.dgpdb.inst2}} -force
srvctl start instance -db {{clu2.dgpdb.dbun}} -instance {{clu2.dgpdb.inst2}} 


---# ----------------------------------------  SCENARIO 3 AND 4: CREATING DGPDB CONFIGURATION
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
sql /@{{clu1.dgpdb.dbun}} as sysdba
show pdbs;
connect /@{{clu2.dgpdb.dbun}} as sysdba
show pdbs;
exit
---# ----------------------------------------  SCENARIO 5a: EXPORT THE KEYS to import to the other CDB
---# exporting the keys is of primordial importance. Each CDB must have the keys of the source CDB$ROOT and source PDB.
---# that means that for every new PDB, its kex must be copied to the destination, unless OKV or KMS are used.
---# here we export, copy the key on the peer cluster, and import
---# for this first part, we are configuring DGPDB for the existing PDBs in the standalone RAC databases.
---# later, we'll move a PDB from the Data Guard Group to this DGPDB configuration.
--- tmux select-pane -t :.0
sql / as sysdba
administer key management export keys with secret "{{input:password}}"
  to '/tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}.wlt' force keystore identified by "{{input:password}}"
  with identifier in (
    select key_id from v$encryption_keys where con_id in (select con_id from v$containers where name in ('CDB$ROOT','{{clu1.dgpdb.pdb_name}}'))
 );
exit
chmod 644 /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}.wlt
--- tmux select-pane -t :.2
sql / as sysdba
administer key management export keys with secret "{{input:password}}"
  to '/tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}.wlt' force keystore identified by "{{input:password}}"
  with identifier in (
    select key_id from v$encryption_keys where con_id in (select con_id from v$containers where name in ('CDB$ROOT','{{clu2.dgpdb.pdb_name}}'))
 );
exit
chmod 644 /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}.wlt
--- tmux select-pane -t :.1
---# ------------------------------------------ TEMPORARY NEW TERMINAL FOR THE COPY OF THE KEYS
exit
exit

---# COPYING SOURCE KEYS LOCALLY
scp {{public_key}} opc@{{clu1.host1.public_ip}}:/tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}.wlt /tmp
scp {{public_key}} opc@{{clu2.host1.public_ip}}:/tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}.wlt /tmp
---# COPYING KEYS TO REMOTE TARGETS
scp {{public_key}} /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}.wlt opc@{{clu2.host1.public_ip}}:/tmp
scp {{public_key}} /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}.wlt opc@{{clu1.host1.public_ip}}:/tmp
---# CHANGING PERMISSIONS
ssh {{public_key}} opc@{{clu2.host1.public_ip}} sudo chown oracle:dba /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}.wlt && echo OK
ssh {{public_key}} opc@{{clu1.host1.public_ip}} sudo chown oracle:dba /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}.wlt && echo OK
---# REMOVE LOCALLY TO CLEANUP
rm /tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}.wlt
rm /tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}.wlt
ssh {{public_key}} opc@{{clu1.host2.public_ip}} 
sudo su - oracle
---# ----------------------------------------  IMPORTING TDE KEYS
--- tmux select-pane -t :.0
sid {{clu1.dgpdb.dbun}}
sql / as sysdba
administer key management import keys with secret "{{input:password}}" from '/tmp/{{clu2.dgpdb.dbun}}_{{clu2.dgpdb.pdb_name}}.wlt'
 force keystore identified by "{{input:password}}" with backup;
exit
--- tmux select-pane -t :.2
sid {{clu2.dgpdb.dbun}}
sql / as sysdba
administer key management import keys with secret "{{input:password}}" from '/tmp/{{clu1.dgpdb.dbun}}_{{clu1.dgpdb.pdb_name}}.wlt'
 force keystore identified by "{{input:password}}" with backup;
exit
---# ----------------------------------------  SCENARIO 5: PREPARE THE DATABASES
--- tmux select-pane -t :.0
dgmgrl /@{{clu2.dgpdb.dbun}}
connect /@{{clu2.dgpdb.dbun}}
ADD PLUGGABLE DATABASE {{clu1.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}} SOURCE IS {{clu1.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}} 
  pdbfilenameconvert is "'/{{clu1.dgpdb.dbun}}/','/{{clu2.dgpdb.dbun}}/'"
  'keystore identified by "{{input:password}}"';
connect /@{{clu1.dgpdb.dbun}}
ADD PLUGGABLE DATABASE {{clu2.dgpdb.pdb_name}} AT {{clu1.dgpdb.dbun}} SOURCE IS {{clu2.dgpdb.pdb_name}} AT {{clu2.dgpdb.dbun}} 
  pdbfilenameconvert is "'/{{clu2.dgpdb.dbun}}/','/{{clu1.dgpdb.dbun}}/'"
  'keystore identified by "{{input:password}}"';
--- tmux resize-pane -t :.0 -Z
--- tmux resize-pane -t :.0 -Z
--- tmux resize-pane -t :.2 -Z
--- tmux resize-pane -t :.2 -Z
---# ----------------------------------------- START THE APPLY
edit pluggable database {{clu1.dgpdb.pdb_name}} at {{clu2.dgpdb.dbun}} set state='APPLY-ON';
edit pluggable database {{clu2.dgpdb.pdb_name}} at {{clu1.dgpdb.dbun}} set state='APPLY-ON';

show all pluggable database at {{clu1.dgpdb.dbun}}
show all pluggable database at {{clu2.dgpdb.dbun}}
show pluggable database {{clu1.dgpdb.pdb_name}} at {{clu1.dgpdb.dbun}}
show pluggable database {{clu1.dgpdb.pdb_name}} at {{clu2.dgpdb.dbun}}
show pluggable database {{clu2.dgpdb.pdb_name}} at {{clu2.dgpdb.dbun}}
show pluggable database {{clu2.dgpdb.pdb_name}} at {{clu1.dgpdb.dbun}}
exit

--- tmux select-pane -t :.0
sql /@{{clu1.dgpdb.dbun}} as sysdba
show pdbs
select name, cause, type, message, status from PDB_PLUG_IN_VIOLATIONS where type = 'ERROR' and status != 'RESOLVED';
select p.pdb_id, p.pdb_name, pr.name, pr.role,  pr.action, pr.sequence#, pr.block# , pr.block_count, pr.con_id, pr.inst_id  from gv$dataguard_process pr, cdb_pdbs p where pr.con_id=p.pdb_id;
select p.pdb_id, p.pdb_name, p.status, dg.name, dg.value, dg.inst_id from gv$dataguard_stats dg, cdb_pdbs p where dg.con_id=p.pdb_id order by p.pdb_id, dg.inst_id;
connect /@{{clu2.dgpdb.dbun}} as sysdba
show pdbs
select name, cause, type, message, status from PDB_PLUG_IN_VIOLATIONS where type = 'ERROR' and status != 'RESOLVED';
select p.pdb_id, p.pdb_name, pr.name, pr.role,  pr.action, pr.sequence#, pr.block# , pr.block_count, pr.con_id, pr.inst_id  from gv$dataguard_process pr, cdb_pdbs p where pr.con_id=p.pdb_id;
select p.pdb_id, p.pdb_name, p.status, dg.name, dg.value, dg.inst_id from gv$dataguard_stats dg, cdb_pdbs p where dg.con_id=p.pdb_id order by p.pdb_id, dg.inst_id;
exit

---# ----------------------------------------  SCENARIO 7: SWITCHOVER
dgmgrl /@{{clu1.dgpdb.dbun}}
set time on
validate pluggable database {{clu2.dgpdb.pdb_name}} at {{clu1.dgpdb.dbun}};
switchover to pluggable database {{clu2.dgpdb.pdb_name}} at {{clu1.dgpdb.dbun}};
show all pluggable database at {{clu1.dgpdb.dbun}}
show all pluggable database at {{clu2.dgpdb.dbun}}
validate pluggable database {{clu1.dgpdb.pdb_name}} at {{clu2.dgpdb.dbun}};
switchover to pluggable database {{clu1.dgpdb.pdb_name}} at {{clu2.dgpdb.dbun}};
show all pluggable database at {{clu1.dgpdb.dbun}}
show all pluggable database at {{clu2.dgpdb.dbun}}
exit

---# ------------------------------------------ NOW THE CONVERSION OF THE PDB FROM DATA GUARD GROUP TO DGPDB
---# ------------------------------------------ SAVE THE DATAFILES FROM THE DGCDB STANDBY
--- tmux select-pane -t :.2
sid dgcdb
sql / as sysdba
alter session set container={{clu1.dgcdb.pdb_name}};
spool /home/oracle/{{clu1.dgcdb.pdb_name}}_datafiles.lst
select f.con_id, t.name, f.rfile#, f.ts#, f.name from v$datafile f join v$tablespace t on (f.ts#=t.ts# and f.con_id=t.con_id) join v$pdbs p on (p.con_id=t.con_id) where p.name='{{clu1.dgcdb.pdb_name}}';
spool off
---# ------------------------------------------ EXPORT THE KEY
--- tmux select-pane -t :.0
exit
rm /tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt
sid dgcdb
sql / as sysdba
alter session set container={{clu1.dgcdb.pdb_name}};
administer key management export keys with secret "{{input:password}}"
  to '/tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt' force keystore identified by "{{input:password}}";
exit
chmod 644 /tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt

--- tmux select-pane -t :.1
---# ------------------------------------------ TEMPORARY NEW TERMINAL FOR THE COPY OF THE KEYS
exit
exit
---# COPYING SOURCE KEYS LOCALLY
scp {{public_key}} opc@{{clu1.host1.public_ip}}:/tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt /tmp
---# COPYING KEYS TO REMOTE TARGETS
scp {{public_key}} /tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt opc@{{clu2.host1.public_ip}}:/tmp
---# CHANGING PERMISSIONS
ssh {{public_key}} opc@{{clu2.host1.public_ip}} sudo chown oracle:dba /tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt && echo OK
---# REMOVE LOCALLY TO CLEANUP
rm /tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt
ssh {{public_key}} opc@{{clu1.host2.public_ip}} 
sudo su - oracle
---# ------------------------------------------ CLOSE THE PDB
--- tmux select-pane -t :.0
sql / as sysdba
alter pluggable database {{clu1.dgcdb.pdb_name}} close immediate instances=all;
---# ------------------------------------------ UNPLUG THE PDB
alter pluggable database {{clu1.dgcdb.pdb_name}} unplug into '/home/oracle/{{clu1.dgcdb.pdb_name}}.xml';
---# ------------------------------------------ DROP THE PDB
show pdbs;
drop pluggable database {{clu1.dgcdb.pdb_name}}  keep datafiles;
exit
---# ------------------------------------------ CREATE PRIMARY PDB NOCOPY
sid dgpdb1
sql / as sysdba
administer key management import keys with secret "{{input:password}}" from '/tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt'
 force keystore identified by "{{input:password}}" with backup;
CREATE PLUGGABLE DATABASE {{clu1.dgcdb.pdb_name}} USING '/home/oracle/{{clu1.dgcdb.pdb_name}}.xml' NOCOPY keystore identified by "{{input:password}}";
---# ------------------------------------------ OPEN PRIMARY PDB
alter pluggable database {{clu1.dgcdb.pdb_name}} open instances=all;
show pdbs
alter session set container=mypdb;
administer key management import keys with secret "{{input:password}}" from '/tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt'
 force keystore identified by "{{input:password}}" with backup;
alter pluggable database {{clu1.dgcdb.pdb_name}} close instances=all;
alter pluggable database {{clu1.dgcdb.pdb_name}} open instances=all;
select name, cause, type, message, status from PDB_PLUG_IN_VIOLATIONS where type = 'ERROR' and status != 'RESOLVED';

---# ------------------------------------------ ADD STANDBY PDB NOCOPY
--- tmux select-pane -t :.2
sid {{clu2.dgpdb.dbun}}
sql / as sysdba
administer key management import keys with secret "{{input:password}}" from '/tmp/{{clu1.dgcdb.dbun}}_{{clu1.dgcdb.pdb_name}}.wlt'
 force keystore identified by "{{input:password}}" with backup;
exit
dgmgrl /@{{clu2.dgpdb.dbun}}
---# notice there's no pdbfilenameconvert. It makes it easier to remap the files manually
ADD PLUGGABLE DATABASE {{clu1.dgcdb.pdb_name}} AT {{clu2.dgpdb.dbun}}
 SOURCE is {{clu1.dgcdb.pdb_name}} AT {{clu1.dgpdb.dbun}}
  NOCOPY
   'keystore identified by "{{input:password}}"' 
   ;
exit
---# ------------------------------------------ RENAME THE DATA FILES
---# the rename of the datafiles is tricky. because we want to reuse the standby data files,
---# there is no automatic process that renames them. this becomes than a manual rename.
---# if the datafiles were saved earlier, it's possible to recreate the rename statement.
---# 
sql / as sysdba
select f.con_id, t.name, f.rfile#, f.ts#, f.name from v$datafile f join v$tablespace t on (f.ts#=t.ts# and f.con_id=t.con_id) join v$pdbs p on (p.con_id=t.con_id) where p.name='{{clu1.dgcdb.pdb_name}}';

---# alternatively, you can find the files on Exascale, but you must know the PDBGUID or go by exclusion
---# on ExaDB-XS you can find the files in the vault from root, using the wallet in $ORACLE_BASE/admin.
---# again, the remapping is manual
exit
sudo su -
# as root
--- tmux resize-pane -t :.3 -Z
--- tmux resize-pane -t :.2 -Z
xsh --wallet /u02/app/oracle/admin/eswallet/ ls @dERxzmmI > /tmp/files.lst
chown oracle /tmp/files.lst
exit
sudo su - oracle
cp /tmp/files.lst /tmp/files2.lst

---# hereby, an example of how to rename the datafiles, AFTER the manual remapping has been done
sid dgpdb2
sql / as sysdba
alter session set container={{clu1.dgcdb.pdb_name}};
alter database rename file
'@.....'
to
'......'
;

-- repeat for each data file
exit

---# ------------------------------------------ APPLY-ON
dgmgrl /@{{clu2.dgpdb.dbun}}
edit pluggable database {{clu1.dgcdb.pdb_name}} at {{clu2.dgpdb.dbun}} set state='APPLY-ON';
show all pluggable database at {{clu2.dgpdb.dbun}}
show pluggable database {{clu1.dgcdb.pdb_name}} at {{clu1.dgpdb.dbun}}
show pluggable database {{clu1.dgcdb.pdb_name}} at {{clu2.dgpdb.dbun}}
exit
---# ------------------------------------------ OPEN
sql / as sysdba
alter pluggable database {{clu1.dgcdb.pdb_name}} open instances=all;

---# ------------------------------------------ CHECK VIOLATIONS AND PROCESS STATUS
show pdbs
select name, cause, type, message, status from PDB_PLUG_IN_VIOLATIONS where type = 'ERROR' and status != 'RESOLVED';
select p.pdb_id, p.pdb_name, pr.name, pr.role,  pr.action, pr.sequence#, pr.block# , pr.block_count, pr.con_id, pr.inst_id  from gv$dataguard_process pr, cdb_pdbs p where pr.con_id=p.pdb_id;
select p.pdb_id, p.pdb_name, p.status, dg.name, dg.value, dg.inst_id from gv$dataguard_stats dg, cdb_pdbs p where dg.con_id=p.pdb_id order by p.pdb_id, dg.inst_id;
exit

---# ----------------------------------------  SCENARIO 7: SWITCHOVER
dgmgrl /@{{clu1.dgpdb.dbun}}
set time on
validate pluggable database {{clu1.dgcdb.pdb_name}} at {{clu2.dgpdb.dbun}};
switchover to pluggable database {{clu1.dgcdb.pdb_name}} at {{clu2.dgpdb.dbun}};
---# after switchover, it might be that the new primary is only open on one instance
show all pluggable database at {{clu1.dgpdb.dbun}}
show all pluggable database at {{clu2.dgpdb.dbun}}
validate pluggable database {{clu1.dgcdb.pdb_name}} at {{clu1.dgpdb.dbun}};
switchover to pluggable database {{clu1.dgcdb.pdb_name}} at {{clu1.dgpdb.dbun}};
show all pluggable database at {{clu1.dgpdb.dbun}}
show all pluggable database at {{clu2.dgpdb.dbun}}
exit