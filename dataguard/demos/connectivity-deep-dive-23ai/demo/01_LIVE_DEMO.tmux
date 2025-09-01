--- tmux split-window
---# ---------------------------------------  CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
ssh opc@adghol0-23.adghol23.misclabs.oraclevcn.com
sudo su - oracle
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
####  THIS IS THE PRIMARY
---# ---------------------------------------- CONNECTION TO THE SECOND HOST
--- tmux select-pane -t :.1
ssh opc@adghol1-23.adghol23.misclabs.oraclevcn.com
sudo su - oracle
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
### THIS IS THE STANDBY
---# ----------------------------------------  CONFIGURING THE PRIMARY
--- tmux select-pane -t :.0
--- tmux resize-pane -Z -t :.0
cat $ORACLE_HOME/network/admin/listener.ora
cat $ORACLE_HOME/network/admin/tnsnames.ora
tnsping adghol_site0
tnsping adghol_site0_dgmgrl
tnsping adghol_site1
tnsping adghol_site1_dgmgrl
---# Here we still use dgmgrl because PREPARE is not in SQLcl
dgmgrl sys/WElcome123##
prepare database for data guard
  with db_unique_name is adghol_site0
  db_recovery_file_dest_size is "200g"
  db_recovery_file_dest is "/u03/app/oracle/fast_recovery_area"
  restart;
---# retry it to show it's idem potent
prepare database for data guard
  with db_unique_name is adghol_site0
  db_recovery_file_dest_size is "200g"
  db_recovery_file_dest is "/u03/app/oracle/fast_recovery_area" ;
exit
--- tmux resize-pane -Z -t :.0
---# ----------------------------------------  CONFIGURING THE STANDBY
--- tmux select-pane -t :.1
sql / as sysdba
shutdown abort
exit
rm -rf /u02/app/oracle/oradata/${ORACLE_UNQNAME,,}/${ORACLE_UNQNAME^^}/*
rm -rf /u03/app/oracle/redo/${ORACLE_UNQNAME^^}/*
rm -f /u02/app/oracle/oradata/${ORACLE_UNQNAME,,}/control01.ctl /u03/app/oracle/fast_recovery_area/${ORACLE_UNQNAME,,}/control02.ctl
cat $ORACLE_HOME/network/admin/listener.ora
sql / as sysdba
startup nomount force
exit
---# ----------------------------------------   DUPLICATE FOR STANDBY
--- tmux select-pane -t :.1
rman \
 target sys/WElcome123##@adghol_site0 \
 auxiliary=sys/WElcome123##@adghol_site1_dgmgrl
run {
allocate channel c1 device type disk;
allocate auxiliary channel a1 device type disk;
allocate auxiliary channel a2 device type disk;
DUPLICATE TARGET DATABASE  FOR STANDBY FROM ACTIVE DATABASE USING BACKUPSET NOFILENAMECHECK;
}
exit
---# ----------------------------------------   FINISH STANDBY CONFIGURATION
--- tmux select-pane -t :.1
sql / as sysdba
select * from v$log;
alter database clear logfile group 1, group 2, group 3;
select * from v$standby_log;
alter database clear logfile group 4, group 5, group 6;
alter system set dg_broker_start=true scope=spfile;
alter system set db_files=1024 scope=spfile;
alter system set log_buffer=256M scope=spfile;
alter system set db_lost_write_protect=typical scope=spfile;
alter system set db_block_checksum=typical scope=spfile;
alter system set db_flashback_retention_target=120 scope=spfile;
alter system set parallel_threads_per_cpu=1 scope=spfile;
alter system set standby_file_management=auto scope=spfile;
startup force mount
exit
---# ----------------------------------------   DATA GUARD CONFIGURATION
sql sys/WElcome123##@adghol_site0 as sysdba
dg create configuration adghol as primary database is adghol_site0 connect identifier is 'adghol_site0';
dg add database adghol_site1 as connect identifier is 'adghol_site1';
dg edit database adghol_site0 set property StaticConnectIdentifier='adghol_site0_dgmgrl';
dg edit database adghol_site1 set property StaticConnectIdentifier='adghol_site1_dgmgrl';
dg enable configuration;
dg show configuration verbose;
dg show configuration;
exit
---# ---------------------------------------- VALIDATE DATA GUARD AND NEW VIEWS
--- tmux resize-pane -Z -t :.1
dgmgrl sys/WElcome123##@adghol_site0
VALIDATE STATIC CONNECT IDENTIFIER FOR ALL;
VALIDATE NETWORK CONFIGURATION FOR ALL;
VALIDATE DATABASE VERBOSE adghol_site0;
VALIDATE DATABASE VERBOSE adghol_site1 ;
---# new in 23ai: strict all. It also shows the reason for ready for switchover: no
VALIDATE DATABASE VERBOSE adghol_site1 STRICT ALL;
VALIDATE DATABASE adghol_site1 SPFILE
---# new in 23ai
VALIDATE DGConnectIdentifier adghol_site0;
VALIDATE DGConnectIdentifier adghol_site1;
exit
sql sys/WElcome123##@adghol_site0 as sysdba
dg edit database adghol_site1 set state=apply-off;
dg edit database adghol_site1 set state=apply-on;
dg edit database adghol_site0 set state=transport-off;
dg edit database adghol_site0 set state=transport-on;
dg edit database adghol_site1 set property logshipping=off;
dg edit database adghol_site1 set property logshipping=on;
select database, connect_identifier, dataguard_role, redo_source, severity, switchover_ready, failover_ready, transport_mode
from v$dg_broker_config;
select member, dataguard_role, property, substr(value,1,20), scope, valid_role from v$dg_broker_property;
select name, role, action, client_role, group#, sequence#, block#, block_count, dest_id  from v$dataguard_process;
---# checks on the standby
connect sys/WElcome123##@adghol_site1 as sysdba
select database, connect_identifier, dataguard_role, redo_source, severity, switchover_ready, failover_ready, transport_mode
from v$dg_broker_config;
select source_db_unique_name, name, value, time_computed, datum_time from v$dataguard_stats;
---# datum time changes
select source_db_unique_name, name, value, time_computed, datum_time from v$dataguard_stats;
select source_db_unique_name, name, value, time_computed, datum_time from v$dataguard_stats;
---# the process PR00 is a parallel recovery slave of MRP0. It should show the sequence and block increasing
select name, role, action, client_role, group#, sequence#, block#, block_count, dest_id  from v$dataguard_process;
---# again to see recovery progress
select name, role, action, client_role, group#, sequence#, block#, block_count, dest_id  from v$dataguard_process where block# != 0;
---# messages
select * from v$dataguard_status;
---# new in 23ai
select flashback_on from v$database;
alter database flashback on;
set serveroutput on
DECLARE
  severity BINARY_INTEGER;
  retcode  BINARY_INTEGER;
BEGIN
  retcode := DBMS_DG.SET_STATE_APPLY_OFF ( member_name => 'adghol_site1', severity => severity);
  dbms_output.put_line('retcode: '||to_char(retcode)||'  severity: '||to_char(severity));
END;
/
---# recovery is off but transport is on
select * from v$dataguard_stats;
alter database flashback on;
select flashback_on from v$database;
select name, role, action, action_dur, client_role, sequence#, block#, dest_id  from v$dataguard_process;
DECLARE
  severity BINARY_INTEGER;
  retcode  BINARY_INTEGER;
BEGIN
  retcode := DBMS_DG.SET_STATE_APPLY_ON ( member_name => 'adghol_site1', severity => severity);
  dbms_output.put_line('retcode: '||to_char(retcode)||'  severity: '||to_char(severity));
END;
/
--- tmux resize-pane -Z -t :.0
exit
---# ---------------------------------------- EXECUTING A SWITCHOVER
--- tmux select-pane -t :.0
dgmgrl sys/WElcome123##@adghol_site0
show configuration
validate database adghol_site1 strict all
switchover to adghol_site1
show configuration verbose
switchover to adghol_site0
show configuration verbose
exit
---# ---------------------------------------- CREATE THE SERVICES ON THE PRIMARY
--- tmux select-pane -t :.1
sql sys/WElcome123##@adghol_site0 as sysdba
alter pluggable database all discard state;
cd ~/database-maa/data-guard/active-data-guard-23ai/prepare-host/scripts/tac
alter session set container=MYPDB;
select name from v$active_services;
---# ingrandisci pane 1
--- tmux resize-pane -Z -t :.1
set echo on
@create_pdb_services.sql
@create_pdb_service_trigger.sql
@execute_pdb_service_trigger.sql
select name from v$active_services;
select name, aq_ha_notification, commit_outcome, session_state_consistency, failover_restore from v$active_services;
exit
cat $ORACLE_HOME/network/admin/tnsnames.ora
--- tmux resize-pane -Z -t :.1
--- tmux select-pane -t :.0
cat $ORACLE_HOME/network/admin/tnsnames.ora
---# ----------------------------------------  CREATE THE APPLICATION USER
--- tmux select-pane -t :.1
sql sys/WElcome123##@MYPDB_RW as sysdba
select sys_context('USERENV','DB_UNIQUE_NAME') db_unique_name , sys_context('USERENV','SERVER_HOST') server_host;
drop user if exists TACUSER cascade;
create user TACUSER identified by WElcome123##;
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
sqlplus tacuser/WElcome123##@MYPDB_RW
col db_unique_name for a40
col server_host for a20
set pages 100 lines 200
select sys_context('USERENV','DB_UNIQUE_NAME') db_unique_name , sys_context('USERENV','SERVER_HOST') server_host from dual;
create table t (a varchar2(50));
select * from t;
set time on
insert into t values ('TAC test');
--- tmux select-pane -t :.0
dgmgrl sys/WElcome123##@adghol_site0
show configuration
set time on
switchover to adghol_site1
--- tmux select-pane -t :.1
commit;
select * from t;
select sys_context('USERENV','DB_UNIQUE_NAME') db_unique_name , sys_context('USERENV','SERVER_HOST') server_host from dual;
exit
--- tmux select-pane -t :.0
switchover to adghol_site0
exit
sql sys/WElcome123##@mypdb_rw as sysdba
select event, old_primary, new_primary, begin_time, end_time from v$dg_broker_role_change;
exit
---# ----------------------------------------  SNAPSHOT STANDBY
--- tmux select-pane -t :.1
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
dgmgrl sys/WElcome123##@adghol_site0
show configuration ;
convert database adghol_site1 to snapshot standby;
show configuration ;
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
sql sys/WElcome123##@adghol_site1 as sysdba
alter pluggable database mypdb open;
connect tacuser/WElcome123##@MYPDB_SNAP
desc t
drop table t;
create table this_wasnt_there (a varchar2(50));
insert into this_wasnt_there values ('Let''s do some tests!');
commit;
exit
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
convert database adghol_site1 to physical standby;
show configuration verbose
exit
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
---# ---------------------------------------  REAL-TIME QUERY 
--- tmux select-pane -t :.1
sql sys/WElcome123##@adghol_site1 as sysdba
alter database open;
alter pluggable database MYPDB open;
select name from v$active_services where con_name='MYPDB';
connect tacuser/WElcome123##@MYPDB_RO
select * from t;
connect sys/WElcome123##@mypdb_ro as sysdba
select open_mode from v$database;
--- tmux select-pane -t :.0
dgmgrl sys/WElcome123##@adghol_site0
---# Real Time Query: ON
show database adghol_site1
exit
--- tmux select-pane -t :.0
sql tacuser/WElcome123##@MYPDB_RW
insert into t values ('Find me on the standby!');
commit;
--- tmux select-pane -t :.1
connect tacuser/WElcome123##@MYPDB_RO
select * from t;
alter session set standby_max_data_delay=0;
select * from t;
alter session sync with primary;
--- tmux select-pane -t :.0
---# --------------------------------------- MAX AVAILABILITY
exit
dgmgrl sys/WElcome123##@adghol_site0
-- show/edit all members new in 23ai
show all members LogXptMode;
edit all members set property LogXptMode='SYNC';
show all members LogXptMode;
EDIT CONFIGURATION  SET PROTECTION MODE  as MaxAvailability;
--- tmux select-pane -t :.1
alter session set standby_max_data_delay=0;
select * from t;
alter session sync with primary;
exit
--- tmux select-pane -t :.0
exit
---# ----------------------------------------- DML REDIRECT
--- tmux select-pane -t :.1
sql tacuser/WElcome123##@MYPDB_RO
insert into t values ('DML test');
---#	    ORA-16000: database or pluggable database open for read-only access
alter session enable ADG_REDIRECT_DML;
insert into t values ('DML test');
commit;
exit
---# ----------------------------------------- AWR SNAPSHOTS
--- tmux select-pane -t :.1
sqlplus / as sysdba
select dbms_workload_repository.create_snapshot from dual;
select dbms_workload_repository.create_snapshot from dual;
@?/rdbms/admin/awrrpti
exit
---# -----------------------------------------  AUTOMATIC BLOCK REPAIR
--- tmux select-pane -t :.1
exit
exit
ssh opc@adghol0-23.adghol23.misclabs.oraclevcn.com
sudo su - oracle
tail -f  /u01/app/oracle/diag/rdbms/${ORACLE_UNQNAME,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
--- tmux select-pane -t :.0
sql / as sysdba
alter session set container=MYPDB;
cd ~/database-maa/data-guard/active-data-guard-23ai/prepare-host/scripts/abr
@01-abmr.sql
@02-abmr.sql
@03-abmr.sql
drop tablespace corruptiontest including contents and datafiles;
exit
--- tmux select-pane -t :.1
--- tmux send-keys -t :.1 C-c
exit
exit
ssh opc@adghol1-23.adghol23.misclabs.oraclevcn.com
sudo su - oracle
