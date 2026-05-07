--- tmux split-window -h
---# ---------------------------------------  SCENARIO 1 & 2: CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
ssh boshost
sudo su - oracle
ps -eaf | grep pmon
sql / as sysdba
select flashback_on, force_logging from v$database;
show parameter dg_broker
show parameter standby_file_management
show parameter log_archive_dest_1
exit
cat $ORACLE_HOME/network/admin/tnsnames.ora
ls -l $ORACLE_HOME/dbs/wallets/dgpdb
cat $ORACLE_HOME/network/admin/sqlnet.ora
sql /@boston_ad1 as sysdba 
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
connect /@newyork_ad2 as sysdba
select key_id, creator_dbname, creator_pdbname, key_use from v$encryption_keys;
exit
---# ---------------------------------------  SCENARIO 1 & 2: CONNECTION TO THE SECOND HOST
--- tmux select-pane -t :.1
ssh nychost
sudo su - oracle
ps -eaf | grep pmon
sql / as sysdba
select flashback_on, force_logging from v$database;
show parameter dg_broker
show parameter standby_file_management
show parameter log_archive_dest_1
exit
cat $ORACLE_HOME/network/admin/tnsnames.ora
ls -l $ORACLE_HOME/dbs/wallets/dgpdb
cat $ORACLE_HOME/network/admin/sqlnet.ora
sql /@boston_ad1 as sysdba 
exit
sql /@newyork_ad2 as sysdba
exit
---# ----------------------------------------  SCENARIO 3 AND 4: CREATING DGPDB CONFIGURATION
--- tmux select-pane -t :.0
dgmgrl /@boston_ad1
show configuration;
exit
---# ----------------------------------------  SCENARIO 5: PREPARE THE DATABASES
sql / as sysdba
show pdbs
exit

--- tmux select-pane -t :.1
dgmgrl /@boston_ad1
show all pluggable database at boston_ad1
show all pluggable database at newyork_ad2
show pluggable database nyc_finance at newyork_ad2
show pluggable database nyc_acct at newyork_ad2

---# ----------------------------------------  SCENARIO 7: SWITCHOVER
validate pluggable database bos_finance at boston_ad1;
switchover to pluggable database bos_finance at boston_ad1;
show all pluggable database at boston_ad1
show all pluggable database at newyork_ad2
validate pluggable database nyc_finance at newyork_ad2;
switchover to pluggable database nyc_finance at newyork_ad2;
exit
--- tmux select-pane -t :.0
sql / as sysdba
show pdbs
exit


--- tmux select-pane -t :.0
-- add pluggable database red at newyork_ad2 source is red at boston_lhr1mg pdbfilenameconvert is "'/BOSTON_LHR1MG/','/NEWYORK_LHR1WX/'" 'keystore identified by "Welcome#Welcome#123"';
Welcome#Welcome#123
Welcome#Welcome#123
add pluggable database fog at boston_lhr1mg source is fog at newyork_ad2 pdbfilenameconvert is "'/NEWYORK_LHR1WX/','/BOSTON_LHR1MG/'" 'keystore identified by "Welcome#Welcome#123"';
show pluggable database all at boston_lhr1mg;
show pluggable database all at newyork_ad2;
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
rman target /@boston_lhr1mg auxiliary /@newyork_ad2 | tee restore_red.log
backup as copy pluggable database red auxiliary format '+DATA';
--- tmux select-pane -t :.1
rman target /@newyork_ad2 auxiliary /@boston_lhr1mg | tee restore_fog.log
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
sqlplus -s /@newyork_ad2 as sysdba <<EOF
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
sqlplus -s /@newyork_ad2 as sysdba <<EOF
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
edit pluggable database red at newyork_ad2 set state='APPLY-ON';
show pluggable database fog at boston_lhr1mg;
show pluggable database red at newyork_ad2;
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
show pluggable database red at newyork_ad2;
switchover to pluggable database red at newyork_ad2;
