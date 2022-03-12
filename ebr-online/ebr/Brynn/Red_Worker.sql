SET DEFINE OFF
SET DEFINE &
@@Wait_Red
CLEAR SCREEN
EXECUTE p('&1')
PROMPT

begin
  :Stmt := q'{
begin
  commit;
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
        