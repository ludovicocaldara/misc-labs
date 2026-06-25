---# tmux-demo-runner variablesFile=tls-redo-authentication-vars.json.nogit
--- tmux split-window -h
---# ---------------------------------------  SCENARIO 1 & 2: CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
ssh opc@{{host1.public_ip}}
---# start with making sure the rules are in place
sudo iptables -I INPUT -p tcp --dport 2484 -j ACCEPT
sudo su - oracle
--- tmux select-pane -t :.1
ssh opc@{{host2.public_ip}}
---# start with making sure the rules are in place
sudo iptables -I INPUT -p tcp --dport 2484 -j ACCEPT
sudo su - oracle

---# ---------------------- ROOT CA CREATION
--- tmux select-pane -t :.0
orapki wallet create -wallet "{{root_wallet}}" -pwd {{input:password}}
orapki wallet add -wallet "{{root_wallet}}" -dn "C=US, CN=ROOT" -keysize 2048 -self_signed -validity 3650 -pwd {{input:password}}
orapki wallet export -wallet "{{root_wallet}}" -dn "C=US, CN=ROOT" -cert "{{root_wallet}}/root_ca_cert.txt" -pwd {{input:password}}

---# --------------   Copy `root_ca_cert.txt` to both DB hosts.
cp {{root_wallet}}/root_ca_cert.txt /tmp
chmod 644 /tmp/root_ca_cert.txt
--- tmux split-window -v
scp opc@{{host1.public_ip}}:/tmp/root_ca_cert.txt $HOME/tls_demo_root_ca_cert.txt
scp $HOME/tls_demo_root_ca_cert.txt opc@{{host2.public_ip}}:/tmp/root_ca_cert.txt
rm $HOME/tls_demo_root_ca_cert.txt
exit
--- tmux select-pane -t :.1
mkdir $HOME/tlsroot
cp /tmp/root_ca_cert.txt $HOME/tlsroot/
chmod 600 $HOME/tlsroot/root_ca_cert.txt
---# become opc
exit
rm /tmp/root_ca_cert.txt
sudo su - oracle

---# ------------------- Create Server Wallet for Primary (single-instance, transport only)

--- tmux select-pane -t :.0
orapki wallet create -wallet "{{tls_wallet}}" -auto_login -pwd {{input:password}}
orapki wallet add -wallet "{{tls_wallet}}" -dn "CN={{host1.name}}.{{host1.domain}}" -keysize 2048 -pwd {{input:password}}
orapki wallet export -wallet "{{tls_wallet}}" -dn "CN={{host1.name}}.{{host1.domain}}" -request "/tmp/{{host1.name}}_req.txt" -pwd {{input:password}}

# Sign CSR on admin host (copy the certificate request and signed request as appropriate)
orapki cert create -wallet "{{root_wallet}}" -request "/tmp/{{host1.name}}_req.txt" -cert "{{tls_wallet}}/{{host1.name}}_cert.txt" -validity 3650 -pwd {{input:password}}
    
# Import CA and signed server cert (no need to copy here: same host)
orapki wallet add -wallet "{{tls_wallet}}" -trusted_cert -cert "{{root_wallet}}/root_ca_cert.txt" -pwd {{input:password}}
orapki wallet add -wallet "{{tls_wallet}}" -user_cert -cert "{{tls_wallet}}/{{host1.name}}_cert.txt" -pwd {{input:password}}

---#    Verify wallet content:
    orapki wallet display -wallet  {{tls_wallet}}


---# -------------------- Create Server Wallet for Standby (single-instance, transport only)

--- tmux select-pane -t :.1
orapki wallet create -wallet "{{tls_wallet}}" -auto_login -pwd {{input:password}}
orapki wallet add -wallet "{{tls_wallet}}" -dn "CN={{host2.name}}.{{host2.domain}}" -keysize 2048 -pwd {{input:password}}
orapki wallet export -wallet "{{tls_wallet}}" -dn "CN={{host2.name}}.{{host2.domain}}" -request "/tmp/{{host2.name}}_req.txt" -pwd {{input:password}}
chmod 644 /tmp/{{host2.name}}_req.txt

--- tmux split-window -v
scp opc@{{host2.public_ip}}:/tmp/{{host2.name}}_req.txt opc@{{host1.public_ip}}:/tmp/{{host2.name}}_req.txt

# Sign CSR on admin host (copy standby_req.txt to the ROOT_WALLET)
--- tmux select-pane -t :.0
orapki cert create -wallet "{{root_wallet}}" -request "/tmp/{{host2.name}}_req.txt" -cert "{{root_wallet}}/{{host2.name}}_cert.txt" -validity 3650 -pwd {{input:password}}
cp {{root_wallet}}/{{host2.name}}_cert.txt /tmp
chmod 644 /tmp/{{host2.name}}_cert.txt

--- tmux select-pane -t :.2
scp opc@{{host1.public_ip}}:/tmp/{{host2.name}}_cert.txt opc@{{host2.public_ip}}:/tmp/{{host2.name}}_cert.txt
exit

--- tmux select-pane -t :.1
# Import CA and signed server cert (copy them to the STANDBY_WALLET)
orapki wallet add -wallet "{{tls_wallet}}" -trusted_cert -cert "{{root_wallet}}/root_ca_cert.txt" -pwd {{input:password}}
orapki wallet add -wallet "{{tls_wallet}}" -user_cert -cert "/tmp/{{host2.name}}_cert.txt" -pwd {{input:password}}

---#  Verify wallet content:

orapki wallet display -wallet  {{tls_wallet}}


----# ----------------------------- Configure listener.ora for TCPS (Primary + Standby)
--- tmux select-pane -t :.0

cat <<EOF > $ORACLE_HOME/network/admin/listener.ora
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = {{host1.name}}.{{host1.domain}})(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCPS)(HOST = {{host1.name}}.{{host1.domain}})(PORT = 2484))
      (ADDRESS = (PROTOCOL = IPC) (KEY=EXTPROC1521))
    )
  )
    
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = {{host1.dbun}}_DGMGRL.{{host1.domain}})
      (ORACLE_HOME = $ORACLE_HOME)
      (SID_NAME = {{host1.oracle_sid}})
    )
  )

WALLET_LOCATION =
  (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = {{tls_wallet}})))
EOF
--- tmux select-pane -t :.1

cat <<EOF > $ORACLE_HOME/network/admin/listener.ora
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = {{host2.name}}.{{host2.domain}})(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCPS)(HOST = {{host2.name}}.{{host2.domain}})(PORT = 2484))
      (ADDRESS = (PROTOCOL = IPC) (KEY=EXTPROC1521))
    )
  )
    
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = {{host2.dbun}}_DGMGRL.{{host2.domain}})
      (ORACLE_HOME = $ORACLE_HOME)
      (SID_NAME = {{host2.oracle_sid}})
    )
  )

WALLET_LOCATION =
  (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = {{tls_wallet}})))
EOF



---# -------------- Configure sqlnet.ora (Primary + Standby)
--- tmux select-pane -t :.0
cat <<EOF >> $ORACLE_HOME/network/admin/sqlnet.ora
# TLS authentication
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY ={{tls_wallet}})))
SSL_CLIENT_AUTHENTICATION=TRUE
SQLNET.AUTHENTICATION_SERVICES = (BEQ,TCPS)
SQLNET.FALLBACK_AUTHENTICATION=TRUE
EOF

--- tmux select-pane -t :.1
cat <<EOF >> $ORACLE_HOME/network/admin/sqlnet.ora
# TLS authentication
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY ={{tls_wallet}})))
SSL_CLIENT_AUTHENTICATION=TRUE
SQLNET.AUTHENTICATION_SERVICES = (BEQ,TCPS)
SQLNET.FALLBACK_AUTHENTICATION=TRUE
EOF

---# -------------- Configure tnsnames.ora with TCPS aliases (primary + standby)

--- tmux select-pane -t :.0
cat <<EOF >> $ORACLE_HOME/network/admin/tnsnames.ora

# TCPS strings
{{host1.dbun}}_TCPS=(DESCRIPTION=(SDU=65535)(SEND_BUF_SIZE=10485760)(RECV_BUF_SIZE=10485760)(ADDRESS=(PROTOCOL=TCPS)(HOST={{host1.name}}.{{host1.domain}})(PORT=2484)) (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME={{host1.name}}.{{host1.domain}})))
{{host2.dbun}}_TCPS=(DESCRIPTION=(SDU=65535)(SEND_BUF_SIZE=10485760)(RECV_BUF_SIZE=10485760)(ADDRESS=(PROTOCOL=TCPS)(HOST={{host2.name}}.{{host2.domain}})(PORT=2484)) (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME={{host2.name}}.{{host2.domain}})))
EOF
--- tmux select-pane -t :.1
cat <<EOF >> $ORACLE_HOME/network/admin/tnsnames.ora

# TCPS strings
{{host1.dbun}}_TCPS=(DESCRIPTION=(SDU=65535)(SEND_BUF_SIZE=10485760)(RECV_BUF_SIZE=10485760)(ADDRESS=(PROTOCOL=TCPS)(HOST={{host1.name}}.{{host1.domain}})(PORT=2484)) (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME={{host1.dbun}}.{{host1.domain}})))
{{host2.dbun}}_TCPS=(DESCRIPTION=(SDU=65535)(SEND_BUF_SIZE=10485760)(RECV_BUF_SIZE=10485760)(ADDRESS=(PROTOCOL=TCPS)(HOST={{host2.name}}.{{host2.domain}})(PORT=2484)) (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME={{host2.dbun}}.{{host2.domain}})))
EOF

---# -------------- Restart listeners and verify TCPS endpoint
--- tmux select-pane -t :.0
lsnrctl stop
lsnrctl start
lsnrctl status
--- tmux select-pane -t :.1
lsnrctl stop
lsnrctl start
lsnrctl status


---# -------------- Restart the databases
--- tmux select-pane -t :.0
sqlplus / as sysdba
startup force
exit
--- tmux select-pane -t :.1
sqlplus / as sysdba
startup force
exit

---# -------------- ## PHASE 1 VALIDATION (MANDATORY BEFORE PHASE 2)

---# Run these checks and confirm all pass:

--- tmux select-pane -t :.0
tnsping {{host1.dbun}}_TCPS
tnsping {{host2.dbun}}_TCPS
sqlplus sys@{{host1.dbun}}_TCPS as sysdba
{{input:password}}
exit
sqlplus sys@{{host2.dbun}}_TCPS as sysdba
{{input:password}}
exit
--- tmux select-pane -t :.1
tnsping {{host1.dbun}}_TCPS
tnsping {{host2.dbun}}_TCPS
sqlplus sys@{{host1.dbun}}_TCPS as sysdba
{{input:password}}
exit
sqlplus sys@{{host2.dbun}}_TCPS as sysdba
{{input:password}}
exit

---# ------------------- Alter DG transport to use TCPS:
--- tmux select-pane -t :.0
dgmgrl sys@{{host1.dbun}}_TCPS
{{input:password}}
VALIDATE DGConnectIdentifier {{host1.dbun}}_TCPS
VALIDATE DGConnectIdentifier {{host2.dbun}}_TCPS
edit database {{host1.dbun}} set property DGConnectIdentifier={{host1.dbun}}_TCPS;
edit database {{host2.dbun}} set property DGConnectIdentifier={{host2.dbun}}_TCPS; 
edit database {{host1.dbun}} reset property StaticConnectIdentifier;
edit database {{host2.dbun}} reset property StaticConnectIdentifier;
validate network configuration for all;
show configuration;
exit

---# --------------------- PHASE 2 - Use TLS as Authentication Method
--- tmux select-pane -t :.0
sqlplus / as sysdba
select file_name, format from v$passwordfile_info;
exit
    
orapwd file=$ORACLE_HOME/dbs/orapw$ORACLE_SID format=12.2 input_file=$ORACLE_HOME/dbs/orapw$ORACLE_SID force=y 
--- tmux select-pane -t :.1
orapwd file=$ORACLE_HOME/dbs/orapw$ORACLE_SID format=12.2 input_file=$ORACLE_HOME/dbs/orapw$ORACLE_SID force=y 


--- tmux select-pane -t :.0
sqlplus / as sysdba
CREATE USER C##REDO_{{host1.dbun}} IDENTIFIED EXTERNALLY AS 'CN={{host1.name}}.{{host1.domain}}' CONTAINER=ALL;
GRANT SYSOPER TO C##REDO_{{host1.dbun}} CONTAINER=ALL;

CREATE USER C##REDO_{{host2.dbun}} IDENTIFIED EXTERNALLY AS 'CN={{host2.name}}.{{host2.domain}}' CONTAINER=ALL;
GRANT SYSOPER TO C##REDO_{{host2.dbun}} CONTAINER=ALL;

select username, sysoper, account_status, external_name, authentication_type from v$pwfile_users;

connect /@{{host1.dbun}}_TCPS as sysoper
connect /@{{host2.dbun}}_TCPS as sysoper

SHOW USER;
SELECT SYS_CONTEXT('USERENV', 'AUTHENTICATION_METHOD') FROM dual;

--- tmux select-pane -t :.1
sqlplus /@{{host1.dbun}}_TCPS as sysoper
connect /@{{host2.dbun}}_TCPS as sysoper

--- tmux select-pane -t :.0
connect / as sysdba
alter system set redo_transport_user=C##REDO_{{host1.dbun}};

--- tmux select-pane -t :.1
connect / as sysdba
alter system set redo_transport_user=C##REDO_{{host2.dbun}};

select dg.name as dg_process, dg.pid as pid, dg.role as role,
    s.sid as sid, s.username as username, s.external_name as external_name, s.machine as machine
  from v$dataguard_process dg join v$process p on p.spid=dg.pid
  join v$session s on s.paddr=p.addr
 where lower(name) like '%rfs%';

exit
--- tmux select-pane -t :.0
exit