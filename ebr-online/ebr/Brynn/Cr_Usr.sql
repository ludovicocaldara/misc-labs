grant
  Create Session,
  Unlimited Tablespace,
  Create Table,
  Create Sequence,
  Create View,
  Create Procedure,
  Create Trigger,
  Create Any Edition,
  Drop Any Edition,
  Alter Session,
  Alter Database
to Usr identified by p
/
alter user Usr enable Editions
/
-- To allow clean up after setting the database default edition
-- Notice that "with grant option" is essential.
grant Use on edition Ora$Base to Usr with grant option
/
grant Execute on Sys.Utl_Recomp to Usr
/
grant Execute on Sys.DBMS_Lock to Usr
/
grant Execute on Sys.DBMS_Pipe to Usr
/
grant Select on Sys.v_$DB_Pipes to Usr
/
grant Select on Sys.v_$Session to Usr
/
grant Select on Sys.DBA_Objects to Usr
/
