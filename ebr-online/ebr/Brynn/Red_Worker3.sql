SET DEFINE OFF
SET DEFINE &
@@Wait_Red
CLEAR SCREEN
EXECUTE p('&1')
PROMPT

begin
  :Stmt := 'commit';
end;
/
@@Execute_Sql

@@Set_Edition_To_New_Edition

begin
  :Stmt := q'{
begin
  insert into t(c) values('&2');
end;}';
end;
/
@@Execute_Sql

@@Show_EV
PROMPT
PROMPT DML is pending
PROMPT
PROMPT ................................................................................
PROMPT
PROMPT
