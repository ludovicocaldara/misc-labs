--- tmux setenv remote_host 140.238.100.79
--- export remote_host=140.238.100.79
--- ## testing ping to server...
--- ping -w 5000 -n 1 ${remote_host} || exit
--- tmux display-message "server ok."
--- tmux split-window
---# ---------------------------------------  CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
sudo su - ansiblectl
ssh opc@dgsima1
--- sleep 1
sudo su - oracle
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
####  THIS IS THE PRIMARY
---# ---------------------------------------- CONNECTION TO THE SECOND HOST
--- tmux select-pane -t :.1
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
sudo su - ansiblectl
ssh opc@dgsima2
--- sleep 1
sudo su - oracle
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
### THIS IS THE STANDBY
---# ----------------------------------------  CONFIGURING THE PRIMARY
--- tmux select-pane -t :.0
sqlplus / as sysdba
alter database flashback on;
alter database force logging;
alter database add standby logfile thread 1 group 11 size 1073741824 ;
alter database add standby logfile thread 1 group 12 size 1073741824 ;
alter database add standby logfile thread 1 group 13 size 1073741824 ;
alter system set db_files=1024 scope=spfile;
alter system set log_buffer=256M scope=spfile;
alter system set db_lost_write_protect=typical scope=spfile;
alter system set db_block_checksum=typical scope=spfile;
alter system set db_flashback_retention_target=1440 scope=spfile;
alter system set parallel_threads_per_cpu=1 scope=spfile;
alter system set standby_file_management=auto scope=spfile;
alter system set dg_broker_start=true scope=spfile;
alter database clear logfile group 11, group 12, group 13;
-- startup force 
---# ----------------------------------------  CONFIGURING THE STANDBY
--- tmux select-pane -t :.1
rm -rf /u02/app/oracle/oradata/${ORACLE_UNQNAME,,}/${ORACLE_UNQNAME^^}/*
rm -rf /u03/app/oracle/redo/${ORACLE_UNQNAME^^}/*
rm -f /u02/app/oracle/oradata/${ORACLE_UNQNAME,,}/control01.ctl /u03/app/oracle/fast_recovery_area/${ORACLE_UNQNAME,,}/control02.ctl
cat $ORACLE_HOME/network/admin/listener.ora
cat $ORACLE_HOME/network/admin/sqlnet.ora
cat $ORACLE_HOME/dbs/initcdgsima.ora | grep name
sqlplus / as sysdba
startup nomount force
exit
---# ----------------------------------------   DUPLICATE FOR STANDBY
rlwrap rman \
 target sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com \
 auxiliary=sys/Welcome#Welcome#123@dgsima2.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1bm_DGMGRL.dbdgsima.misclabs.oraclevcn.com
run {
allocate channel c1 device type disk;
allocate auxiliary channel a1 device type disk;
allocate auxiliary channel a2 device type disk;
DUPLICATE TARGET DATABASE  FOR STANDBY FROM ACTIVE DATABASE USING BACKUPSET NOFILENAMECHECK;
}
exit
---# ----------------------------------------   DATA GUARD CONFIGURATION
--- tmux select-pane -t :.1
sqlplus / as sysdba
alter database add standby logfile thread 1 group 11 size 1073741824 ;
alter database add standby logfile thread 1 group 12 size 1073741824 ;
alter database add standby logfile thread 1 group 13 size 1073741824 ;
alter database clear logfile group 11, group 12, group 13;
alter database clear logfile group 1, group 2, group 3;
exit
dgmgrl sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com
create configuration cdgsima primary database is cdgsima_lhr1pq connect identifier is 'dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com';
add database cdgsima_lhr1bm as connect identifier is 'dgsima2.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1bm.dbdgsima.misclabs.oraclevcn.com';
edit database cdgsima_lhr1bm set property StaticConnectIdentifier='dgsima2.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1bm_DGMGRL.dbdgsima.misclabs.oraclevcn.com';
edit database cdgsima_lhr1pq set property StaticConnectIdentifier='dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq_DGMGRL.dbdgsima.misclabs.oraclevcn.com';
---# edit database cdgsima_lhr1bm set property LogXptMode='SYNC';
---# edit database cdgsima_lhr1pq set property LogXptMode='SYNC';
enable configuration;
--- tmux resize-pane -Z -t :.1
VALIDATE STATIC CONNECT IDENTIFIER FOR ALL;
VALIDATE NETWORK CONFIGURATION FOR ALL;
VALIDATE DATABASE VERBOSE cdgsima_lhr1pq;
VALIDATE DATABASE VERBOSE cdgsima_lhr1bm;
show configuration verbose;
show database verbose cdgsima_lhr1bm;
show database verbose cdgsima_lhr1pq;
edit database cdgsima_lhr1bm set state='APPLY-OFF';
edit database cdgsima_lhr1bm set state='APPLY-ON';
edit database cdgsima_lhr1pq set state='TRANSPORT-OFF';
edit database cdgsima_lhr1pq set state='TRANSPORT-ON';
--- tmux resize-pane -Z -t :.1
exit
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
---# ---------------------------------------- SHOWING THE PROCESSES ON THE PRIMARY
--- tmux select-pane -t :.0
exit
sql sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com as sysdba
set sqlformat ansiconsole
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
alter session set nls_timestamp_format='YYYY-MM-DD HH24:MI:SS';
--- tmux resize-pane -Z -t :.0
select * from v$dataguard_config;
select * from v$dataguard_process;
---# ---------------------------------------- SHOWING THE PROCESSES ON THE STANDBY
--- tmux select-pane -t :.0
connect sys/Welcome#Welcome#123@dgsima2.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1bm.dbdgsima.misclabs.oraclevcn.com as sysdba
select * from v$dataguard_config;
select * from v$dataguard_stats;
select * from v$dataguard_status;
---# the process PR00 is a parallel recovery slave of MRP0. It should show the sequence and block increasing
select * from v$dataguard_process;
select * from v$managed_standby;
select * from v$standby_log;
--- tmux resize-pane -Z -t :.0
exit
---# ---------------------------------------- EXECUTING A SWITCHOVER
--- tmux select-pane -t :.0
--- tmux resize-pane -Z -t :.0
rlwrap dgmgrl sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com
show configuration
validate database cdgsima_lhr1bm
set time on
switchover to cdgsima_lhr1bm
show configuration
exit
--- tmux resize-pane -Z -t :.0
---# ---------------------------------------- CREATE THE SERVICES ON THE PRIMARY (WHICH IS ON NODE 2 NOW)
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
cd ~/tac
sql / as sysdba
alter session set container=PDGSIMA;
select name from v$active_services where con_id>=2;
--- tmux resize-pane -Z -t :.1
set echo on
@/home/oracle/tac/create_pdb_services.sql
@/home/oracle/tac/create_pdb_service_trigger.sql
@/home/oracle/tac/execute_pdb_service_trigger.sql
select name from v$active_services where con_id>=2;
set sqlformat ansiconsole
select name, aq_ha_notification, commit_outcome, session_state_consistency, failover_restore from v$active_services where con_id >=2;
exit
cat $ORACLE_HOME/network/admin/tnsnames.ora
--- tmux resize-pane -Z -t :.1
--- tmux select-pane -t :.0
cat $ORACLE_HOME/network/admin/tnsnames.ora
---# ----------------------------------------  CREATE THE APPLICATION USER
--- tmux select-pane -t :.1
rlwrap sqlplus sys/Welcome#Welcome#123@PDGSIMA_RW.dbdgsima.misclabs.oraclevcn.com as sysdba
alter session set container=PDGSIMA;
drop user TACUSER cascade;
create user TACUSER identified by Welcome#Welcome#123;
CREATE ROLE TAC_ROLE NOT IDENTIFIED ;
GRANT CREATE TYPE TO TAC_ROLE ;
GRANT CREATE VIEW TO TAC_ROLE ;
GRANT CREATE TABLE TO TAC_ROLE ;
GRANT ALTER SESSION TO TAC_ROLE ;
GRANT CREATE CLUSTER TO TAC_ROLE ;
GRANT CREATE SESSION TO TAC_ROLE ;
GRANT CREATE SYNONYM TO TAC_ROLE ;
GRANT CREATE TRIGGER TO TAC_ROLE ;
GRANT CREATE OPERATOR TO TAC_ROLE ;
GRANT CREATE SEQUENCE TO TAC_ROLE ;
GRANT CREATE INDEXTYPE TO TAC_ROLE ;
GRANT CREATE PROCEDURE TO TAC_ROLE ;
GRANT DROP ANY DIRECTORY TO TAC_ROLE ;
GRANT CREATE ANY DIRECTORY TO TAC_ROLE ;
GRANT SELECT ANY DICTIONARY TO TAC_ROLE ;
GRANT KEEP DATE TIME TO TAC_ROLE;
GRANT KEEP SYSGUID TO TAC_ROLE;
GRANT TAC_ROLE TO TACUSER;
ALTER USER TACUSER QUOTA UNLIMITED ON USERS;
exit
---# ---------------------------------------- TRANSPARENT APPLICATION CONTINUITY
rlwrap sqlplus tacuser/Welcome#Welcome#123@PDGSIMA_RW.dbdgsima.misclabs.oraclevcn.com
select sys_context('USERENV','DB_UNIQUE_NAME') , sys_context('USERENV','SERVER_HOST') from dual;
create table t (a varchar2(50));
select * from t;
insert into t values ('TAC test');
--- tmux select-pane -t :.0
rlwrap dgmgrl sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com
show configuration
set time on
switchover to cdgsima_lhr1pq
--- tmux select-pane -t :.1
commit;
select * from t;
select sys_context('USERENV','DB_UNIQUE_NAME') , sys_context('USERENV','SERVER_HOST') from dual;
exit
--- tmux select-pane -t :.0
exit
---# ----------------------------------------  SNAPSHOT STANDBY
--- tmux select-pane -t :.1
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
rlwrap dgmgrl sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com
show configuration verbose;
convert database cdgsima_lhr1bm to snapshot standby;
show configuration verbose;
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
rlwrap sqlplus tacuser/Welcome#Welcome#123@PDGSIMA_SNAP.dbdgsima.misclabs.oraclevcn.com
desc t
drop table t;
create table this_wasnt_there (a varchar2(50));
insert into this_wasnt_there values ('Let''s do some tests!');
commit;
exit
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
convert database cdgsima_lhr1bm to physical standby;
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
rlwrap sqlplus / as sysdba
alter database open;
alter pluggable database pdgsima open;
select name from v$active_services where con_id>=2;
exit
---# ---------------------------------------  REAL-TIME QUERY 
rlwrap sqlplus tacuser/Welcome#Welcome#123@PDGSIMA_RO.dbdgsima.misclabs.oraclevcn.com
desc t
select * from this_wasnt_there;
exit
--- tmux select-pane -t :.0
show database cdgsima_lhr1bm
---# Real Time Query:    ON
exit
---# tmux resize-pane -Z -t :.0
rlwrap sqlplus tacuser/Welcome#Welcome#123@PDGSIMA_RW.dbdgsima.misclabs.oraclevcn.com      
insert into t values ('Find me on the standby!');
commit;
--- tmux select-pane -t :.1
rlwrap sqlplus tacuser/Welcome#Welcome#123@PDGSIMA_RO.dbdgsima.misclabs.oraclevcn.com      
select * from t;
alter session set standby_max_data_delay=0;
select * from t;
alter session sync with primary;
exit
--- tmux select-pane -t :.0
---# --------------------------------------- MAX AVAILABILITY
exit
rlwrap dgmgrl sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com
edit database cdgsima_lhr1bm set property LogXptMode='SYNC';
edit database cdgsima_lhr1pq set property LogXptMode='SYNC';
EDIT CONFIGURATION  SET PROTECTION MODE  as MaxAvailability;
--- tmux select-pane -t :.1
rlwrap sqlplus tacuser/Welcome#Welcome#123@PDGSIMA_RO.dbdgsima.misclabs.oraclevcn.com      
alter session set standby_max_data_delay=0;
select * from t;
alter session sync with primary;
exit
--- tmux select-pane -t :.0
exit
---# ----------------------------------------- DML REDIRECT
--- tmux select-pane -t :.1
rlwrap sqlplus tacuser/Welcome#Welcome#123@PDGSIMA_RO.dbdgsima.misclabs.oraclevcn.com
insert into t values ('DML test');
---#	    ORA-16000: database or pluggable database open for read-only access
alter session enable ADG_REDIRECT_DML;
insert into t values ('DML test');
commit;
exit
---# -----------------------------------------  AUTOMATIC BLOCK REPAIR
--- tmux select-pane -t :.1
exit
exit
ssh opc@dgsima1
sudo su - oracle
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
rlwrap sqlplus / as sysdba
alter session set container=PDGSIMA;
@01-abmr.sql
@02-abmr.sql
@03-abmr.sql
drop tablespace corruptiontest including contents and datafiles;
exit
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
exit
exit
ssh opc@dgsima2
sudo su - oracle
---# ------------------------------------------- FAR SYNC
--- tmux select-pane -t :.0
[ -d /u02/app/oracle/oradata/cdgsima_farsync1/ ] || mkdir -p /u02/app/oracle/oradata/cdgsima_farsync1/
rlwrap sqlplus / as sysdba
ALTER DATABASE CREATE FAR SYNC INSTANCE CONTROLFILE AS '/u02/app/oracle/oradata/cdgsima_farsync1/control01.ctl' reuse;
exit
export ORACLE_SID=farsync
export ORACLE_UNQNAME=cdgsima_farsync1
cat <<EOF > $ORACLE_HOME/dbs/initfarsync.ora
*.compatible='19.0.0'
*.control_files='/u02/app/oracle/oradata/cdgsima_farsync1/control01.ctl'
*.db_block_checking='MEDIUM'
*.db_block_checksum='TYPICAL'
*.db_create_online_log_dest_1='/u03/app/oracle/redo/'
*.db_domain='dbdgsima.misclabs.oraclevcn.com'
*.db_files=1024
*.db_lost_write_protect='TYPICAL'
*.db_name='cdgsima'
*.db_recovery_file_dest_size=250g
*.db_recovery_file_dest='/u03/app/oracle/fast_recovery_area'
*.db_unique_name='cdgsima_farsync1'
*.dg_broker_start=TRUE
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=cdgsimaXDB)'
*.enable_ddl_logging=TRUE
*.enable_pluggable_database=true
*.encrypt_new_tablespaces='ALWAYS'
*.filesystemio_options='setall'
*.global_names=TRUE
*.log_buffer=16m
*.nls_language='AMERICAN'
*.nls_territory='AMERICA'
*.open_cursors=300
*.parallel_threads_per_cpu=1
*.pga_aggregate_limit=4096M
*.pga_aggregate_target=2048M
*.processes=100
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=2048M
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
EOF
cp $ORACLE_HOME/dbs/orapwcdgsima $ORACLE_HOME/dbs/orapwfarsync
rm -f $ORACLE_HOME/dbs/spfilefarsync.ora
rlwrap sqlplus / as sysdba
startup mount
create spfile from pfile='$ORACLE_HOME/dbs/initfarsync.ora';
startup force mount
alter database clear logfile group 11, group 12, group 13;
--- tmux select-pane -t :.1
[ -d /u02/app/oracle/oradata/cdgsima_farsync2/ ] || mkdir /u02/app/oracle/oradata/cdgsima_farsync2/
rlwrap sqlplus / as sysdba
ALTER DATABASE CREATE FAR SYNC INSTANCE CONTROLFILE AS '/u02/app/oracle/oradata/cdgsima_farsync2/control01.ctl' reuse;
exit
export ORACLE_SID=farsync
export ORACLE_UNQNAME=cdgsima_farsync2
cat <<EOF >  $ORACLE_HOME/dbs/initfarsync.ora
*.compatible='19.0.0'
*.control_files='/u02/app/oracle/oradata/cdgsima_farsync2/control01.ctl'
*.db_block_checking='MEDIUM'
*.db_block_checksum='TYPICAL'
*.db_create_online_log_dest_1='/u03/app/oracle/redo/'
*.db_domain='dbdgsima.misclabs.oraclevcn.com'
*.db_files=1024
*.db_lost_write_protect='TYPICAL'
*.db_name='cdgsima'
*.db_recovery_file_dest_size=250g
*.db_recovery_file_dest='/u03/app/oracle/fast_recovery_area'
*.db_unique_name='cdgsima_farsync2'
*.dg_broker_start=TRUE
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=cdgsimaXDB)'
*.enable_ddl_logging=TRUE
*.enable_pluggable_database=true
*.encrypt_new_tablespaces='ALWAYS'
*.filesystemio_options='setall'
*.global_names=TRUE
*.log_buffer=16m
*.nls_language='AMERICAN'
*.nls_territory='AMERICA'
*.open_cursors=300
*.parallel_threads_per_cpu=1
*.pga_aggregate_limit=4096M
*.pga_aggregate_target=2048M
*.processes=100
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=2048M
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
EOF
cp $ORACLE_HOME/dbs/orapwcdgsima $ORACLE_HOME/dbs/orapwfarsync
rm -f $ORACLE_HOME/dbs/spfilefarsync.ora
rlwrap sqlplus / as sysdba
startup mount
create spfile from pfile='$ORACLE_HOME/dbs/initfarsync.ora';
startup force mount
alter database clear logfile group 11, group 12, group 13;
--- tmux select-pane -t :.0
--- tmux resize-pane -Z -t :.0
exit
rlwrap dgmgrl sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com
show configuration;
ADD FAR_SYNC cdgsima_farsync1 AS CONNECT IDENTIFIER IS dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_farsync1.dbdgsima.misclabs.oraclevcn.com;
ADD FAR_SYNC cdgsima_farsync2 AS CONNECT IDENTIFIER IS dgsima2.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_farsync2.dbdgsima.misclabs.oraclevcn.com;
show configuration;
ENABLE FAR_SYNC cdgsima_farsync1
ENABLE FAR_SYNC cdgsima_farsync2
edit far_sync cdgsima_farsync2 set property LogXptMode ='SYNC';
edit far_sync cdgsima_farsync1 set property LogXptMode ='SYNC';
disable configuration
EDIT DATABASE 'cdgsima_lhr1pq' SET PROPERTY 'RedoRoutes' = '(LOCAL : (cdgsima_farsync1 SYNC PRIORITY=1, cdgsima_lhr1bm ASYNC PRIORITY=2 ))';
EDIT FAR_SYNC 'cdgsima_farsync1' SET PROPERTY 'RedoRoutes' = '(cdgsima_lhr1pq : cdgsima_lhr1bm ASYNC)';
EDIT DATABASE 'cdgsima_lhr1bm' SET PROPERTY 'RedoRoutes' = '(LOCAL : (cdgsima_farsync2 SYNC PRIORITY=1, cdgsima_lhr1pq ASYNC PRIORITY=2 ))';
EDIT FAR_SYNC 'cdgsima_farsync2' SET PROPERTY 'RedoRoutes' = '(cdgsima_lhr1bm : cdgsima_lhr1pq ASYNC)';
show configuration;
enable configuration
show configuration;
show configuration when primary is cdgsima_lhr1pq
show configuration when primary is cdgsima_lhr1bm
EDIT DATABASE 'cdgsima_lhr1pq' SET PROPERTY 'RedoRoutes' = '(LOCAL : (cdgsima_lhr1bm SYNC))';
EDIT DATABASE 'cdgsima_lhr1bm' SET PROPERTY 'RedoRoutes' = '(LOCAL : (cdgsima_lhr1pq SYNC))';
REMOVE FAR_SYNC 'cdgsima_farsync1';
REMOVE FAR_SYNC 'cdgsima_farsync2';
show configuration;
--- tmux resize-pane -Z -t :.0
exit
export ORACLE_SID=farsync
rlwrap sqlplus / as sysdba
shutdown ;
exit
--- tmux select-pane -t :.1
exit
export ORACLE_SID=farsync
rlwrap sqlplus / as sysdba
shutdown ;
exit
