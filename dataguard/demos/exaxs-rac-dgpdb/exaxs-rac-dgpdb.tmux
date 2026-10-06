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