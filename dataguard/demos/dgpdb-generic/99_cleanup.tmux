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

---# ----------------------------------------  STOP THE APPLY
--- tmux select-pane -t :.0
rlwrap dgmgrl / as sysdba
edit pluggable database fog at boston_lhr1mg set state='APPLY-OFF';
edit pluggable database red at newyork_lhr1wx set state='APPLY-OFF';
remove pluggable database fog at boston_lhr1mg;
remove pluggable database red at newyork_lhr1wx;
remove configuration newyork;
remove configuration all;
---# ----------------------------------------- TO CONTINUE
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
