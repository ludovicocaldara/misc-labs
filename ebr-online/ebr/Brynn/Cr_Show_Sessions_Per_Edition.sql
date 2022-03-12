-- BULK COLLECT used without the LIMIT clause
alter session set Plsql_warnings = 'Error:All, Disable:07207'
/
create or replace noneditionable procedure Usr.Show_Sessions_Per_Edition authid Definer is
  Cur Sys_Refcursor;

  Stmt constant varchar2(32767) not null := q'{
select o.Object_Name Edition_Name, Count(*) n
from Sys.v_$Session s inner join Sys.DBA_Objects o
on s.Session_Edition_ID = o.Object_ID
where s.User# <> 0
and s.Type = 'USER'
and o.Object_Type = 'EDITION'
group by o.Object_Name
order by 1 desc}';

  type r is record(
    Object_Name Sys.DBA_Objects.Object_Name %type,
    n           integer);
  type t is table of r index by pls_integer;
  Sessions_Per_Edition t;

begin
  open Cur for Stmt;
  fetch Cur bulk collect into Sessions_Per_Edition;
  close Cur;

  if Sessions_Per_Edition.Count() > 0 then
    DBMS_Output.Put_Line(
      Rpad('Edition', 8)||
      '  n');
    DBMS_Output.Put_Line(
      Rpad('-------', 8)||
      ' --');
  else
    Raise_Application_Error(-20000, 'All sessions are authorized as Sys');
  end if;

  for j in 1..Sessions_Per_Edition.Count() loop
    DBMS_Output.Put_Line(
      Rpad(Sessions_Per_Edition(j).Object_Name, 8)||
      To_Char(Sessions_Per_Edition(j).n, '99'));
  end loop;
end Show_Sessions_Per_Edition;
/
alter session set Plsql_warnings = 'Error:All'
/
