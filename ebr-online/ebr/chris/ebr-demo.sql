conn chris/chris
@ebr-setup


set define off
select user from dual;

create or replace function hello_user
  return varchar2 as
begin

  return 'Hello ' || user;
  
end hello_user;
/

create or replace procedure display_user as
begin
  dbms_output.put_line ( hello_user() );
end display_user;
/

set serveroutput on
exec display_user;


create edition release_001;
/*
grant use 
  on edition release_001 
  to ebr_user;
*/

select * from dba_editions;

select sys_context('userenv', 'session_edition_name') as edition 
from   dual;

alter session set edition = release_001;

select sys_context('userenv', 'session_edition_name') as edition 
from   dual;


/* V2; add parameter to function */
create or replace function hello_user ( 
  display_user varchar2 default user
) return varchar2 as
begin

  return 'Hello ' || display_user;
  
end hello_user;
/



select object_name, object_type, edition_name, status
from   all_objects_ae
where  owner = 'EBR_USER'
order  by object_name, edition_name ;



exec display_user;



select object_name, object_type, edition_name, last_ddl_time
from   all_objects_ae
where  owner = 'EBR_USER'
order  by object_name, edition_name ;




create edition release_002;
/* 
grant use 
  on edition release_002 
  to ebr_user;
*/

alter session set edition = release_002;


/* V3: use new parameter in procedure */
create or replace procedure display_user as
begin
  dbms_output.put_line ( hello_user ( 'Oracle Open World and Code One!' ) );
end display_user;
/

select object_name, object_type, edition_name 
from   all_objects_ae
where  owner = 'EBR_USER'
order  by object_name, edition_name ;



exec display_user;



select object_name, object_type, edition_name 
from   all_objects_ae
where  owner = 'EBR_USER'
order  by object_name, edition_name ;




alter function hello_user
  compile;

select object_name, object_type, edition_name
from   all_objects_ae
where  owner = 'EBR_USER'
order  by object_name, edition_name ;





/* Can't explicitly reference the edition */
exec ora$base.ebr_user.display_user;
exec release_001.ebr_user.display_user;
exec release_002.ebr_user.display_user;




alter session set edition = ora$base;

exec ebr_user.display_user;

alter session set edition = release_001;

exec ebr_user.display_user;

alter session set edition = release_002;

exec ebr_user.display_user;





/* Rollback! */
drop edition release_002 cascade;

alter session set edition = release_001;

drop edition release_002 cascade;

select * from dba_editions;

/*
revoke use 
  on edition ora$base
  from public;
  
alter database default edition = release_001;
*/