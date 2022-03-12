DISCONNECT
CLEAR SCREEN
VARIABLE Stmt VARCHAR2(4000)
SPOOL Red.txt
WHENEVER SQLERROR EXIT
@@Connect_As_Usr
@@Set_Edition_To_Old_Edition
PROMPT Ready to start.
PROMPT
PROMPT
--------------------------------------------------------------------------------
@@Red_Worker   '2. Cause pending DML in table t_.'              'starling'
@@Red_Worker   '5. Commit. Cause new pending DML in table t_.'  'thrush'
@@Red_Worker2  '8. Commit. Cause new pending DML in table t_.'  'owl'
@@Red_Worker2 '11. Commit. Cause new pending DML in table t_.'  'finch'
@@Red_Worker2 '14. Commit. Cause new pending DML in table t_.'  'warbler'
@@Red_Worker  '17. Commit. Cause new pending DML in table t_.'  'jackdaw'
@@Red_Worker  '20. Commit. Cause new pending DML in table t_.'  'blackbird'
@@Red_Worker  '23. Commit. Cause new pending DML in table t_.'  'woodpecker'

-- Swtiches to edition e1
@@Red_Worker3 '26. Commit. Cause new pending DML in table t_.'  'hawk'
@@Red_Worker  '29. Commit. Cause new pending DML in table t_.'  'eagle'

PROMPT
PROMPT In the same an ad hoc SQL*Plus session...
PROMPT
PROMPT insert into t(c) values('Manual 12345678901')
PROMPT /
PROMPT commit
PROMPT /
PROMPT select * from t_ order by PK
PROMPT /
PROMPT

@@Red_Worker  '32. Commit. Cause new pending DML in table t_.'  'sparrow 12345678901'
@@Red_Worker  '35. Commit. Cause new pending DML in table t_.'  'pigeon 12345678901'
@@Red_Worker  '38. Commit. Cause new pending DML in table t_.'  'chaffinch 12345678901'

@@Wait_Red
CLEAR SCREEN
PROMPT 41. Final commit.
PROMPT
EXECUTE :Stmt := 'commit'
@@Execute_Sql
PROMPT
@@Show_EV
PROMPT
PROMPT ................................................................................
WHENEVER SQLERROR CONTINUE
PROMPT
PROMPT
PROMPT Done!
PROMPT
SPOOL OFF
