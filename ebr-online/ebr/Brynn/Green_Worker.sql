SET DEFINE OFF
SET DEFINE &
@@Wait_Green
CLEAR SCREEN
EXECUTE p('&1')
PROMPT

begin
  :Stmt := q'{
begin
  insert into t(c) values('&2');
  commit;
end;}';
end;
/
@@Execute_Sql
PROMPT
PROMPT DML was not blocked

@@Show_EV
PROMPT
PROMPT ................................................................................
PROMPT
PROMPT
