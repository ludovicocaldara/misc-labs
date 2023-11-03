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
ssh opc@hol23c0.dbhol23c
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
ssh opc@hol23c1.dbhol23c
--- sleep 1
sudo su - oracle
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
### THIS IS THE STANDBY
---# ----------------------------------------  CONFIGURING THE PRIMARY
--- tmux select-pane -t :.0
--- tmux resize-pane -Z -t :.0
dgmgrl sys/Welcome#Welcome#123
prepare database for data guard
  with db_unique_name is chol23c_rxd_lhr
  db_recovery_file_dest_size is "200g"
  db_recovery_file_dest is "/u03/app/oracle/fast_recovery_area"
  restart;
---# retry it to show it's idem potent
prepare database for data guard
  with db_unique_name is chol23c_rxd_lhr
  db_recovery_file_dest_size is "200g"
  db_recovery_file_dest is "/u03/app/oracle/fast_recovery_area" ;
exit
--- tmux resize-pane -Z -t :.0
cat $ORACLE_HOME/network/admin/listener.ora
lsnrctl reload
---# ----------------------------------------  CONFIGURING THE STANDBY
--- tmux select-pane -t :.1
sqlplus / as sysdba
shutdown abort
exit
rm -rf /u02/app/oracle/oradata/${ORACLE_UNQNAME,,}/${ORACLE_UNQNAME^^}/*
rm -rf /u03/app/oracle/redo/${ORACLE_UNQNAME^^}/*
rm -f /u02/app/oracle/oradata/${ORACLE_UNQNAME,,}/control01.ctl /u03/app/oracle/fast_recovery_area/${ORACLE_UNQNAME,,}/control02.ctl
cat $ORACLE_HOME/network/admin/listener.ora
lsnrctl reload

sqlplus / as sysdba
startup nomount force
exit
---# ----------------------------------------   DUPLICATE FOR STANDBY
--- tmux select-pane -t :.1
rman \
 target sys/Welcome#Welcome#123@hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com \
 auxiliary=sys/Welcome#Welcome#123@hol23c1.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_r2j_lhr_DGMGRL.dbhol23c.misclabs.oraclevcn.com
run {
allocate channel c1 device type disk;
allocate auxiliary channel a1 device type disk;
allocate auxiliary channel a2 device type disk;
DUPLICATE TARGET DATABASE  FOR STANDBY FROM ACTIVE DATABASE USING BACKUPSET NOFILENAMECHECK;
}
exit
---# ----------------------------------------   FINISH STANDBY CONFIGURATION
--- tmux select-pane -t :.1
sqlplus / as sysdba
select * from v$standby_log;
alter database clear logfile group 4, group 5, group 6;
alter database clear logfile group 1, group 2, group 3;
alter system set dg_broker_start=true scope=spfile;
alter system set db_files=1024 scope=spfile;
alter system set log_buffer=256M scope=spfile;
alter system set db_lost_write_protect=typical scope=spfile;
alter system set db_block_checksum=typical scope=spfile;
alter system set db_flashback_retention_target=120 scope=spfile;
alter system set parallel_threads_per_cpu=1 scope=spfile;
alter system set standby_file_management=auto scope=spfile;
startup force mount
alter database flashback on;
exit
---# ----------------------------------------   DATA GUARD CONFIGURATION
dgmgrl sys/Welcome#Welcome#123@hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com
create configuration chol23c primary database is chol23c_rxd_lhr connect identifier is 'hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com';
add database chol23c_r2j_lhr as connect identifier is 'hol23c1.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_r2j_lhr.dbhol23c.misclabs.oraclevcn.com';
edit database chol23c_rxd_lhr set property StaticConnectIdentifier='hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr_DGMGRL.dbhol23c.misclabs.oraclevcn.com';
edit database chol23c_r2j_lhr set property StaticConnectIdentifier='hol23c1.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_r2j_lhr_DGMGRL.dbhol23c.misclabs.oraclevcn.com';
enable configuration;
--- tmux resize-pane -Z -t :.1
VALIDATE STATIC CONNECT IDENTIFIER FOR ALL;
VALIDATE NETWORK CONFIGURATION FOR ALL;
VALIDATE DATABASE VERBOSE chol23c_rxd_lhr;
---# new in 23c: parameter and property mismatch at the end
VALIDATE DATABASE VERBOSE chol23c_r2j_lhr ;

---# new in 23c: strict all
VALIDATE DATABASE VERBOSE chol23c_r2j_lhr STRICT ALL;
VALIDATE DATABASE chol23c_r2j_lhr SPFILE
---# new in 23c
VALIDATE DGConnectIdentifier hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com;
VALIDATE DGConnectIdentifier hol23c1.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_r2j_lhr.dbhol23c.misclabs.oraclevcn.com;

show configuration verbose;
edit database chol23c_r2j_lhr set state=apply-off;
edit database chol23c_r2j_lhr set state=apply-on;
edit database chol23c_rxd_lhr set state=transport-off;
edit database chol23c_rxd_lhr set state=transport-on;
edit database chol23c_r2j_lhr set property logshipping=off;
edit database chol23c_r2j_lhr set property logshipping=on;
--- tmux resize-pane -Z -t :.1
exit
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
---# ---------------------------------------- SHOWING THE PROCESSES ON THE PRIMARY
--- tmux select-pane -t :.0
sql sys/Welcome#Welcome#123@hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com as sysdba
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
alter session set nls_timestamp_format='YYYY-MM-DD HH24:MI:SS';
--- tmux resize-pane -Z -t :.0
select * from v$dataguard_config;
select name, role, action, client_role, group#, sequence#, block#, block_count, dest_id  from v$dataguard_process;
---# ---------------------------------------- SHOWING THE PROCESSES ON THE STANDBY
--- tmux select-pane -t :.0
connect sys/Welcome#Welcome#123@hol23c1.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_r2j_lhr.dbhol23c.misclabs.oraclevcn.com as sysdba
select * from v$dataguard_config;
select * from v$dataguard_stats;
select * from v$dataguard_status;
---# the process PR00 is a parallel recovery slave of MRP0. It should show the sequence and block increasing
select name, role, action, client_role, group#, sequence#, block#, block_count, dest_id  from v$dataguard_process;
---# new in 23c
select member, dataguard_role, property, value, scope, valid_role from v$dg_broker_property;
set serveroutput on
DECLARE
  severity BINARY_INTEGER;
  retcode  BINARY_INTEGER;
BEGIN
  retcode := DBMS_DG.SET_STATE_APPLY_OFF ( member_name => 'chol23c_r2j_lhr', severity => severity);
  dbms_output.put_line('retcode: '||to_char(retcode)||'  severity: '||to_char(severity));
END;
/
select * from v$dataguard_stats;
select name, role, action, action_dur, client_role, sequence#, block#, dest_id  from v$dataguard_process;
DECLARE
  severity BINARY_INTEGER;
  retcode  BINARY_INTEGER;
BEGIN
  retcode := DBMS_DG.SET_STATE_APPLY_ON ( member_name => 'chol23c_r2j_lhr', severity => severity);
  dbms_output.put_line('retcode: '||to_char(retcode)||'  severity: '||to_char(severity));
END;
/
--- tmux resize-pane -Z -t :.0
exit
---# ---------------------------------------- EXECUTING A SWITCHOVER
--- tmux select-pane -t :.0
dgmgrl sys/Welcome#Welcome#123@hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com
show configuration
validate database chol23c_r2j_lhr strict all
set time on
switchover to chol23c_r2j_lhr
show configuration
exit
---# ---------------------------------------- CREATE THE SERVICES ON THE PRIMARY (WHICH IS ON NODE 2 NOW)
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
sql / as sysdba
alter session set container=PHOL23C;
select name from v$active_services where con_id>=2;
--- tmux resize-pane -Z -t :.1
set echo on
@/home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/tac/create_pdb_services.sql
@/home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/tac/create_pdb_service_trigger.sql
@/home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/tac/execute_pdb_service_trigger.sql
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
sql sys/Welcome#Welcome#123@PHOL23C_RW.dbhol23c.misclabs.oraclevcn.com as sysdba
alter session set container=PHOL23C;
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
sqlplus tacuser/Welcome#Welcome#123@PHOL23C_RW.dbhol23c.misclabs.oraclevcn.com
col db_unique_name for a40
col server_host for a20
set pages 100 lines 200
select sys_context('USERENV','DB_UNIQUE_NAME') db_unique_name , sys_context('USERENV','SERVER_HOST') server_host from dual;
create table t (a varchar2(50));
select * from t;
insert into t values ('TAC test');
--- tmux select-pane -t :.0
dgmgrl sys/Welcome#Welcome#123@hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com
show configuration
set time on
switchover to chol23c_rxd_lhr
--- tmux select-pane -t :.1
commit;
select * from t;
select sys_context('USERENV','DB_UNIQUE_NAME') db_unique_name , sys_context('USERENV','SERVER_HOST') server_host from dual;
exit
--- tmux select-pane -t :.0
exit
---# ----------------------------------------  SNAPSHOT STANDBY
--- tmux select-pane -t :.1
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
dgmgrl sys/Welcome#Welcome#123@hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com
show configuration ;
convert database chol23c_r2j_lhr to snapshot standby;
show configuration ;
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
sql tacuser/Welcome#Welcome#123@PHOL23C_SNAP.dbhol23c.misclabs.oraclevcn.com
desc t
drop table t;
create table this_wasnt_there (a varchar2(50));
insert into this_wasnt_there values ('Let''s do some tests!');
commit;
exit
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
convert database chol23c_r2j_lhr to physical standby;
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
sqlplus / as sysdba
alter database open;
alter pluggable database PHOL23C open;
select name from v$active_services where con_id>=2;
exit
---# ---------------------------------------  REAL-TIME QUERY 
sqlplus tacuser/Welcome#Welcome#123@PHOL23C_RO.dbhol23c.misclabs.oraclevcn.com
desc t
select * from this_wasnt_there;
exit
--- tmux select-pane -t :.0
show database chol23c_r2j_lhr
---# Real Time Query:    ON
exit
---# tmux resize-pane -Z -t :.0
sqlplus tacuser/Welcome#Welcome#123@PHOL23C_RW.dbhol23c.misclabs.oraclevcn.com      
insert into t values ('Find me on the standby!');
commit;
--- tmux select-pane -t :.1
sqlplus tacuser/Welcome#Welcome#123@PHOL23C_RO.dbhol23c.misclabs.oraclevcn.com      
select * from t;
alter session set standby_max_data_delay=0;
select * from t;
alter session sync with primary;
exit
--- tmux select-pane -t :.0
---# --------------------------------------- MAX AVAILABILITY
exit
dgmgrl sys/Welcome#Welcome#123@hol23c0.dbhol23c.misclabs.oraclevcn.com:1521/chol23c_rxd_lhr.dbhol23c.misclabs.oraclevcn.com
-- show/edit all members new in 23c
show all members LogXptMode;
edit all members set property LogXptMode='SYNC';
show all members LogXptMode;
EDIT CONFIGURATION  SET PROTECTION MODE  as MaxAvailability;
--- tmux select-pane -t :.1
rlwrap sqlplus tacuser/Welcome#Welcome#123@PHOL23C_RO.dbhol23c.misclabs.oraclevcn.com      
alter session set standby_max_data_delay=0;
select * from t;
alter session sync with primary;
exit
--- tmux select-pane -t :.0
exit
---# ----------------------------------------- DML REDIRECT
--- tmux select-pane -t :.1
rlwrap sqlplus tacuser/Welcome#Welcome#123@PHOL23C_RO.dbhol23c.misclabs.oraclevcn.com
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
ssh opc@hol23c0.dbhol23c
sudo su - oracle
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
sqlplus / as sysdba
alter session set container=PHOL23C;
@/home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/abr/01-abmr.sql
@/home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/abr/02-abmr.sql
@/home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/abr/03-abmr.sql
drop tablespace corruptiontest including contents and datafiles;
exit
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
exit
exit
ssh opc@hol23c1
sudo su - oracle
