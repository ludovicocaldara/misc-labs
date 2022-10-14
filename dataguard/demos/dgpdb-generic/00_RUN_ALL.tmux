--- tmux setenv remote_host 140.238.100.79
--- export remote_host=140.238.100.79
--- ## testing ping to server...
--- ping -w 5000 -n 1 ${remote_host} || exit
--- tmux display-message "server ok."
---# --------------------------------------- CREATE FOUR PANES
---# --------------------------------------- 
---# |                  |                  |
---# |       .0         |        .1        |
---# |                  |                  |
---# |                  |                  |
---# --------------------------------------- 
---# |                  |                  |
---# |       .2         |        .3        |
---# |                  |                  |
---# |                  |                  |
---# --------------------------------------- 
--- tmux split-window
--- tmux select-pane -t :.0
--- tmux split-window -h
--- tmux select-pane -t :.2
--- tmux split-window -h
--- tmux select-pane -t :.0
---# tmux resize-pane -R 10
---# tmux resize-pane -L 10

---# ---------------------------------------  CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
ssh opc@boston1.dbdgprac
--- sleep 1
sudo sed -i -e s/^TMOUT/#TMOUT/ /etc/profile
sudo su - oracle
if ! [ -d ~/COE ] ; then git clone https://github.com/ludovicocaldara/COE.git ; echo ". ~/COE/profile.sh" >> $HOME/.bash_profile ; . ~/.bash_profile ; fi
clear
ps -eaf | grep pmon
---# ---------------------------------------  CONNECTION TO THE SECOND HOST
--- tmux select-pane -t :.1
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
ssh opc@boston2.dbdgprac
--- sleep 1
sudo sed -i -e s/^TMOUT/#TMOUT/ /etc/profile
sudo su - oracle
if ! [ -d ~/COE ] ; then git clone https://github.com/ludovicocaldara/COE.git ; echo ". ~/COE/profile.sh" >> $HOME/.bash_profile ; . ~/.bash_profile ; fi
clear
ps -eaf | grep pmon
---# ---------------------------------------  CONNECTION TO THE THIRD HOST
--- tmux select-pane -t :.2
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
ssh opc@newyork1.dbdgprac
--- sleep 1
sudo sed -i -e s/^TMOUT/#TMOUT/ /etc/profile
sudo su - oracle
if ! [ -d ~/COE ] ; then git clone https://github.com/ludovicocaldara/COE.git ; echo ". ~/COE/profile.sh" >> $HOME/.bash_profile ; . ~/.bash_profile ; fi
clear
ps -eaf | grep pmon
---# ---------------------------------------  CONNECTION TO THE FOURTH HOST
--- tmux select-pane -t :.3
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
ssh opc@newyork2.dbdgprac
--- sleep 1
sudo sed -i -e s/^TMOUT/#TMOUT/ /etc/profile
sudo su - oracle
if ! [ -d ~/COE ] ; then git clone https://github.com/ludovicocaldara/COE.git ; echo ". ~/COE/profile.sh" >> $HOME/.bash_profile ; . ~/.bash_profile ; fi
clear
ps -eaf | grep pmon
---# ----------------------------------------  CONFIGURING BOSTON FOR PRIMARY ROLE
--- tmux select-pane -t :.0
rlwrap sqlplus / as sysdba
alter system set dg_broker_start=false;
alter system set dg_broker_config_file1='+DATA/BOSTON_LHR1MG/dg1.cfg';
alter system set dg_broker_config_file2='+DATA/BOSTON_LHR1MG/dg2.cfg';
alter system set dg_broker_start=true;
alter system set standby_file_management=auto;
-- force logging is enabled by default on DBCS
exit
---# ----------------------------------------  CONFIGURING NEWYORK FOR PRIMARY ROLE
--- tmux select-pane -t :.2
rlwrap sqlplus / as sysdba
alter system set dg_broker_start=false;
alter system set dg_broker_config_file1='+DATA/NEWYORK_LHR1WX/dg1.cfg';
alter system set dg_broker_config_file2='+DATA/NEWYORK_LHR1WX/dg2.cfg';
alter system set dg_broker_start=true;
alter system set standby_file_management=auto;
-- force logging is enabled by default on DBCS
exit
---# ----------------------------------------  ADDING THE CORRECT CONNECTION STRINGS EVERYWHERE
--- tmux select-pane -t :.0
cat <<EOF > $(orabasehome)/network/admin/tnsnames.ora
NEWYORK_LHR1WX = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = newyork-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = newyork_lhr1wx.dbdgprac.misclabs.oraclevcn.com)))
BOSTON_LHR1MG = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = boston-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = boston_lhr1mg.dbdgprac.misclabs.oraclevcn.com)))
EOF
--- tmux select-pane -t :.1
cat <<EOF > $(orabasehome)/network/admin/tnsnames.ora
NEWYORK_LHR1WX = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = newyork-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = newyork_lhr1wx.dbdgprac.misclabs.oraclevcn.com)))
BOSTON_LHR1MG = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = boston-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = boston_lhr1mg.dbdgprac.misclabs.oraclevcn.com)))
EOF
--- tmux select-pane -t :.2
cat <<EOF > $(orabasehome)/network/admin/tnsnames.ora
NEWYORK_LHR1WX = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = newyork-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = newyork_lhr1wx.dbdgprac.misclabs.oraclevcn.com)))
BOSTON_LHR1MG = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = boston-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = boston_lhr1mg.dbdgprac.misclabs.oraclevcn.com)))
EOF
--- tmux select-pane -t :.3
cat <<EOF > $(orabasehome)/network/admin/tnsnames.ora
NEWYORK_LHR1WX = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = newyork-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = newyork_lhr1wx.dbdgprac.misclabs.oraclevcn.com)))
BOSTON_LHR1MG = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = boston-scan.dbdgprac.misclabs.oraclevcn.com)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = boston_lhr1mg.dbdgprac.misclabs.oraclevcn.com)))
EOF
---# ----------------------------------------  ADDING THE WALLET POINTERS TO LOCAL SQLNET.ORA FILES
--- tmux select-pane -t :.0
grep ^WALLET_LOCATION $(orabasehome)/network/admin/sqlnet.ora >/dev/null
if [ $? -ne 0 ] ; then
cat <<EOF >> $(orabasehome)/network/admin/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)(METHOD_DATA= (DIRECTORY=/opt/oracle/dcs/commonstore/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_CLIENT_AUTHENTICATION = FALSE
SSL_VERSION = 0
EOF
fi
cat $(orabasehome)/network/admin/sqlnet.ora
--- tmux select-pane -t :.1
grep ^WALLET_LOCATION $(orabasehome)/network/admin/sqlnet.ora >/dev/null
if [ $? -ne 0 ] ; then
cat <<EOF >> $(orabasehome)/network/admin/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)(METHOD_DATA= (DIRECTORY=/opt/oracle/dcs/commonstore/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_CLIENT_AUTHENTICATION = FALSE
SSL_VERSION = 0
EOF
fi
cat $(orabasehome)/network/admin/sqlnet.ora
--- tmux select-pane -t :.2
grep ^WALLET_LOCATION $(orabasehome)/network/admin/sqlnet.ora >/dev/null
if [ $? -ne 0 ] ; then
cat <<EOF >> $(orabasehome)/network/admin/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)(METHOD_DATA= (DIRECTORY=/opt/oracle/dcs/commonstore/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_CLIENT_AUTHENTICATION = FALSE
SSL_VERSION = 0
EOF
fi
cat $(orabasehome)/network/admin/sqlnet.ora
--- tmux select-pane -t :.3
grep ^WALLET_LOCATION $(orabasehome)/network/admin/sqlnet.ora >/dev/null
if [ $? -ne 0 ] ; then
cat <<EOF >> $(orabasehome)/network/admin/sqlnet.ora
WALLET_LOCATION= (SOURCE= (METHOD=file)(METHOD_DATA= (DIRECTORY=/opt/oracle/dcs/commonstore/wallets/client)))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_CLIENT_AUTHENTICATION = FALSE
SSL_VERSION = 0
EOF
fi
cat $(orabasehome)/network/admin/sqlnet.ora
---# ----------------------------------------  CREATING THE WALLETS ONCE PER CLUSTER (THEY ARE ON SHARED STORAGE)
--- tmux select-pane -t :.0
WLTLOC=/opt/oracle/dcs/commonstore/wallets/client
mkdir -p $WLTLOC
mkstore -wrl ${WLTLOC} -create
Welcome#Welcome#123
Welcome#Welcome#123
mkstore -wrl ${WLTLOC} -createCredential newyork_lhr1wx sys
Welcome#Welcome#123
Welcome#Welcome#123
Welcome#Welcome#123
mkstore -wrl ${WLTLOC} -createCredential boston_lhr1mg sys
Welcome#Welcome#123
Welcome#Welcome#123
Welcome#Welcome#123
--- tmux select-pane -t :.2
WLTLOC=/opt/oracle/dcs/commonstore/wallets/client
mkdir -p $WLTLOC
mkstore -wrl ${WLTLOC} -create
Welcome#Welcome#123
Welcome#Welcome#123
mkstore -wrl ${WLTLOC} -createCredential newyork_lhr1wx sys
Welcome#Welcome#123
Welcome#Welcome#123
Welcome#Welcome#123
mkstore -wrl ${WLTLOC} -createCredential boston_lhr1mg sys
Welcome#Welcome#123
Welcome#Welcome#123
Welcome#Welcome#123
---# ----------------------------------------  RESTARTING THE BROKER TO GET THE WALLET PARAMETERS (one instance affects the other)
--- tmux select-pane -t :.0
rlwrap sqlplus / as sysdba
alter system set dg_broker_start=false;
alter system set dg_broker_start=true;
alter system set global_names=false;
exit
--- tmux select-pane -t :.2
rlwrap sqlplus / as sysdba
alter system set dg_broker_start=false;
alter system set dg_broker_start=true;
alter system set global_names=false;
exit
---# ----------------------------------------  CREATING DGPDB CONFIGURATION
--- tmux select-pane -t :.0
--- tmux resize-pane -R 50
rlwrap dgmgrl /@boston_lhr1mg
create configuration boston primary database is boston_lhr1mg connect identifier is boston_lhr1mg;
show configuration;
add configuration newyork connect identifier is newyork_lhr1wx;
show configuration;
enable configuration all;
show configuration;
---# ----------------------------------------  CREATING TARGET PDBS
--- tmux select-pane -t :.2
--- tmux resize-pane -R 50
rlwrap sqlplus /@boston_lhr1mg as sysdba 
select open_mode from v$pdbs where name='RED'; 
connect /@newyork_lhr1wx as sysdba 
select open_mode from v$pdbs where name='FOG'; 
exit
--- tmux select-pane -t :.0
add pluggable database red at newyork_lhr1wx source is red at boston_lhr1mg pdbfilenameconvert is "'/BOSTON_LHR1MG/','/NEWYORK_LHR1WX/'" 'keystore identified by "Welcome#Welcome#123"';
Welcome#Welcome#123
Welcome#Welcome#123
add pluggable database fog at boston_lhr1mg source is fog at newyork_lhr1wx pdbfilenameconvert is "'/NEWYORK_LHR1WX/','/BOSTON_LHR1MG/'" 'keystore identified by "Welcome#Welcome#123"';
show pluggable database all at boston_lhr1mg;
show pluggable database all at newyork_lhr1wx;
---# ----------------------------------------  EXPORTING TDE KEYS
--- tmux select-pane -t :.1
--- tmux select-layout tiled
rlwrap sqlplus / as sysdba
select key_id from v$encryption_keys where con_id in (1, (select con_id from v$pdbs where name='RED'));
administer key management export keys with secret "Welcome#Welcome#123" to '/tmp/red.wlt' 
force keystore identified by "Welcome#Welcome#123" 
with identifier in ( select key_id from v$encryption_keys
 where con_id in (1, (select con_id from v$pdbs where name='RED')));
--- tmux select-pane -t :.3
rlwrap sqlplus / as sysdba
select key_id from v$encryption_keys where con_id in (1, (select con_id from v$pdbs where name='FOG'));
administer key management export keys with secret "Welcome#Welcome#123" to '/tmp/fog.wlt'
force keystore identified by "Welcome#Welcome#123" 
with identifier in ( select key_id from v$encryption_keys
 where con_id in (1, (select con_id from v$pdbs where name='FOG')));
---# ----------------------------------------  COPYING THE KEYS WITH SCP
--- tmux select-pane -t :.2
exit 
exit 
# COPYING RED KEYS
scp opc@boston2.dbdgprac:/tmp/red.wlt /tmp
scp /tmp/red.wlt opc@newyork2.dbdgprac:/tmp
scp /tmp/red.wlt opc@newyork1.dbdgprac:/tmp
ssh opc@newyork2.dbdgprac sudo chown oracle:dba /tmp/red.wlt && echo OK
ssh opc@newyork2.dbdgprac sudo chmod 600 /tmp/red.wlt && echo OK
ssh opc@newyork1.dbdgprac sudo chown oracle:dba /tmp/red.wlt && echo OK
ssh opc@newyork1.dbdgprac sudo chmod 600 /tmp/red.wlt && echo OK
rm /tmp/red.wlt
# COPYING FOG KEYS
scp opc@newyork2.dbdgprac:/tmp/fog.wlt /tmp
scp /tmp/fog.wlt opc@boston2.dbdgprac:/tmp
scp /tmp/fog.wlt opc@boston1.dbdgprac:/tmp
rm /tmp/fog.wlt
ssh opc@boston2.dbdgprac sudo chown oracle:dba /tmp/fog.wlt && echo OK
ssh opc@boston2.dbdgprac sudo chmod 600 /tmp/fog.wlt && echo OK
ssh opc@boston1.dbdgprac sudo chown oracle:dba /tmp/fog.wlt && echo OK
ssh opc@boston1.dbdgprac sudo chmod 600 /tmp/fog.wlt && echo OK
ssh opc@newyork1.dbdgprac
sudo su - oracle
---# ----------------------------------------  IMPORTING TDE KEYS
--- tmux select-pane -t :.1
administer key management import keys with secret "Welcome#Welcome#123" from '/tmp/fog.wlt' force keystore identified by "Welcome#Welcome#123" with backup;
--- tmux select-pane -t :.3
administer key management import keys with secret "Welcome#Welcome#123" from '/tmp/red.wlt' force keystore identified by "Welcome#Welcome#123" with backup;
---# ----------------------------------------  CREATING THE SRLs
--- tmux select-pane -t :.1
alter session set container=fog;
alter database add standby logfile thread 1 group 5 size 1073741824;
alter database add standby logfile thread 1 group 6 size 1073741824;
alter database add standby logfile thread 2 group 7 size 1073741824;
alter database add standby logfile thread 2 group 8 size 1073741824;
exit
--- tmux select-pane -t :.3
alter session set container=red;
alter database add standby logfile thread 1 group 5 size 1073741824;
alter database add standby logfile thread 1 group 6 size 1073741824;
alter database add standby logfile thread 2 group 7 size 1073741824;
alter database add standby logfile thread 2 group 8 size 1073741824;
exit
---# ----------------------------------------  RESTORE THE RED DATABASE
--- tmux select-pane -t :.3
rman target /@boston_lhr1mg auxiliary /@newyork_lhr1wx | tee restore_red.log
backup as copy pluggable database red auxiliary format '+DATA';
--- tmux select-pane -t :.1
rman target /@newyork_lhr1wx auxiliary /@boston_lhr1mg | tee restore_fog.log
backup as copy pluggable database fog auxiliary format '+DATA';
---# ----------------------------------------  RENAME THE RED DATAFILES
--- tmux select-pane -t :.3
exit
rm -f dgpdb.sqlite
echo "create table rman (num integer, old varchar(400), new varchar(400));" | sqlite3 dgpdb.sqlite
echo "create table source (num integer, rnum integer);" | sqlite3 dgpdb.sqlite
echo "create table dest (num integer, rnum integer, name varchar(400));" | sqlite3 dgpdb.sqlite
cat restore_red.log | awk '{ if (/^input/) { fnum=substr($4,index($4,"=")+1); old=substr($NF,index($NF,"=")+1)} if (/^output/) { new=substr($3,index($3,"=")+1); printf ("insert into rman values ('\''%d'\'', '\''%s'\'', '\''%s'\'');\n", fnum, old, new) }}' | sqlite3 dgpdb.sqlite
{
sqlplus -s /@boston_lhr1mg as sysdba <<EOF
set head off feed off
select 'insert into source values ('||file#||','||rfile#||');' from v\$datafile where con_id=(select con_id from v\$pdbs where name='RED');
EOF
} | sqlite3 dgpdb.sqlite
{
sqlplus -s /@newyork_lhr1wx as sysdba <<EOF
set head off feed off
set lines 400
alter session set container=RED;
select 'insert into dest values ('||file#||','||rfile#||','''||name||''');' from v\$datafile where con_id=(select con_id from v\$pdbs where name='RED');
EOF
} | sqlite3 dgpdb.sqlite
echo "select 'alter database rename file '''||d.name||''' to '''||r.new||''';' from dest d join source s on (d.rnum=s.rnum) join rman r on (s.num=r.num);" | sqlite3 dgpdb.sqlite | tee rename_red.log
sqlplus / as sysdba 
alter session set container=RED;
set echo on
@rename_red.log
exit

---# ----------------------------------------  RENAME THE FOG DATAFILES
--- tmux select-pane -t :.1
exit
rm -f dgpdb.sqlite
echo "create table rman (num integer, old varchar(400), new varchar(400));" | sqlite3 dgpdb.sqlite
echo "create table source (num integer, rnum integer);" | sqlite3 dgpdb.sqlite
echo "create table dest (num integer, rnum integer, name varchar(400));" | sqlite3 dgpdb.sqlite
cat restore_fog.log | awk '{ if (/^input/) { fnum=substr($4,index($4,"=")+1); old=substr($NF,index($NF,"=")+1)} if (/^output/) { new=substr($3,index($3,"=")+1); printf ("insert into rman values ('\''%d'\'', '\''%s'\'', '\''%s'\'');\n", fnum, old, new) }}' | sqlite3 dgpdb.sqlite
{
sqlplus -s /@newyork_lhr1wx as sysdba <<EOF
set head off feed off
select 'insert into source values ('||file#||','||rfile#||');' from v\$datafile where con_id=(select con_id from v\$pdbs where name='FOG');
EOF
} | sqlite3 dgpdb.sqlite
{
sqlplus -s /@boston_lhr1mg as sysdba <<EOF
set head off feed off
set lines 400
alter session set container=FOG;
select 'insert into dest values ('||file#||','||rfile#||','''||name||''');' from v\$datafile where con_id=(select con_id from v\$pdbs where name='FOG');
EOF
} | sqlite3 dgpdb.sqlite
echo "select 'alter database rename file '''||d.name||''' to '''||r.new||''';' from dest d join source s on (d.rnum=s.rnum) join rman r on (s.num=r.num);" | sqlite3 dgpdb.sqlite | tee rename_fog.log
sqlplus / as sysdba 
alter session set container=FOG;
set echo on
@rename_fog.log
exit
---# ----------------------------------------  START THE APPLY
--- tmux select-pane -t :.0
--- tmux resize-pane -R 50
edit pluggable database fog at boston_lhr1mg set state='APPLY-ON';
edit pluggable database red at newyork_lhr1wx set state='APPLY-ON';
show pluggable database fog at boston_lhr1mg;
show pluggable database red at newyork_lhr1wx;
---# ----------------------------------------  VERIFY THE RECOVERY IS ACTIVE
--- tmux select-pane -t :.2
--- tmux resize-pane -R 50
sql / as sysdba
set sqlformat ansiconsole
select p.pdb_id, p.pdb_name, pr.name, pr.pid, pr.type, pr.role,  pr.action, pr.client_pid, pr.client_role, pr.group#, pr.thread#,  pr.sequence#, pr.block# , pr.block_count, pr.con_id, pr.inst_id  from gv$dataguard_process pr, cdb_pdbs p where pr.con_id=p.pdb_id;
select p.pdb_id, p.pdb_name, p.status, dg.name, dg.value, dg.inst_id from gv$dataguard_stats dg, cdb_pdbs p where dg.con_id=p.pdb_id order by p.pdb_id, dg.inst_id;
---# tmux select-pane -t :.3
---# tmux resize-pane -Z :.3
---# tmux select-layout tiled
--- tmux select-pane -t :.0
show pluggable database red at newyork_lhr1wx;
switchover to pluggable database red at newyork_lhr1wx;
