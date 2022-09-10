--- tmux setenv remote_host 140.238.100.79
--- export remote_host=140.238.100.79
--- ## testing ping to server...
--- ping -w 5000 -n 1 ${remote_host} || exit
--- tmux display-message "server ok."

--- tmux split-window
---#
---# ----------------------------------------------
---# CONNECTION TO THE FIRST HOST
---# ----------------------------------------------
--- tmux select-pane -t :.0
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
--- 
sudo su - ansiblectl
ssh opc@dgsima1
--- sleep 1
sudo su - oracle
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
# THIS IS THE PRIMARY
---#
---# ----------------------------------------------
---# CONNECTION TO THE SECOND HOST
---# ----------------------------------------------
--- tmux select-pane -t :.1
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
--- 
sudo su - ansiblectl
ssh opc@dgsima2
--- sleep 1
sudo su - oracle
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
# THIS IS THE STANDBY
---# ----------------------------------------------
--- ## CONFIGURING THE PRIMARY
---# ----------------------------------------------
--- tmux select-pane -t :.0
dgmgrl sys/Welcome#Welcome#123@dgsima1.dbdgsima.misclabs.oraclevcn.com:1521/cdgsima_lhr1pq.dbdgsima.misclabs.oraclevcn.com
switchover to cdgsima_lhr1pq
edit database cdgsima_lhr1bm set state='APPLY-OFF';
EDIT CONFIGURATION SET PROTECTION MODE AS MaxPerformance;
remove configuration;
exit
--- tmux select-pane -t :.1
rlwrap sqlplus / as sysdba
shutdown abort
exit
--- tmux select-pane -t :.0
sqlplus / as sysdba
alter session set container=PDGSIMA;
drop tablespace CORRUPTIONTEST including contents and datafiles;
DECLARE

	CURSOR c_services IS
		SELECT  name  FROM SYS.service$ WHERE upper(name) != upper(rtrim(sys_context('userenv','db_name')||'.'|| sys_context('userenv','db_domain'), '.'))
		 AND upper(name) != upper(rtrim(sys_context('userenv','db_name')))
		 AND upper(name) like upper(rtrim(sys_context('userenv','db_name')))||'%';

	r_services c_services%ROWTYPE;
	e_service_error EXCEPTION;
	PRAGMA EXCEPTION_INIT (e_service_error    , -44786);

        e_not_in_pdb EXCEPTION;
        PRAGMA EXCEPTION_INIT (e_not_in_pdb, -20101);

	e_no_trigger EXCEPTION;
        PRAGMA EXCEPTION_INIT (e_no_trigger, -4080);

BEGIN

	-- check if currently in a PDB
     --   IF sys_context('userenv','con_name') = 'CDB$ROOT' THEN
                --raise_application_error(-20101,'The current container is CDB$ROOT. It must be a PDB.');
        --END IF;

	OPEN c_services;
	LOOP
		FETCH  c_services  INTO r_services;
		EXIT WHEN c_services%NOTFOUND;
		BEGIN
			DBMS_SERVICE.STOP_SERVICE (service_name => r_services.name);
		EXCEPTION
			WHEN DBMS_SERVICE.SERVICE_NOT_RUNNING THEN  null;
			WHEN DBMS_SERVICE.SERVICE_DOES_NOT_EXIST THEN  null;
			WHEN e_service_error THEN  null;
		END;

		BEGIN
			DBMS_SERVICE.DELETE_SERVICE (service_name => r_services.name);
		EXCEPTION
			WHEN DBMS_SERVICE.SERVICE_DOES_NOT_EXIST THEN  null;
		END;
	END LOOP;

	BEGIN
		EXECUTE IMMEDIATE 'DROP TRIGGER service_trigger';
	EXCEPTION
		WHEN e_no_trigger THEN NULL;
	END; 
END;
/
exit
