DISCONNECT
CLEAR SCREEN
VARIABLE Stmt VARCHAR2(4000)
SPOOL Green.txt
WHENEVER SQLERROR EXIT
@@Connect_As_Usr
@@Set_Edition_To_Old_Edition
PROMPT Ready to start.
PROMPT
PROMPT
--------------------------------------------------------------------------------

@@Green_Worker   '4. Insert a row into t_ and commit'       'cat'
@@Green_Worker   '7. Insert another row into t_ and commit' 'dog'
@@Green_Worker  '10. Insert another row into t_ and commit' 'lamb'
@@Green_Worker  '13. Insert another row into t_ and commit' 'llama'
@@Green_Worker  '16. Insert another row into t_ and commit' 'mouse'
@@Green_Worker  '19. Insert another row into t_ and commit' 'rabbit'
@@Green_Worker  '22. Insert another row into t_ and commit' 'horse'

@@Green_Worker2 '25. Insert another row into t_ and commit' 'pig'

PROMPT
PROMPT Start an ad hoc SQL*Plus session...
PROMPT @@Connect_As_Usr
PROMPT @@Set_Edition_To_New_Edition
PROMPT insert into t(c) values('12345678901')
PROMPT

@@Green_Worker  '28. Insert another row into t_ and commit' 'cow'
@@Green_Worker  '31. Insert another row into t_ and commit' 'sheep 12345678901'
@@Green_Worker  '34. Insert another row into t_ and commit' 'goat 12345678901'
@@Green_Worker  '37. Insert another row into t_ and commit' 'elephant 12345678901'
@@Green_Worker  '40. Insert another row into t_ and commit' 'zebra 12345678901'

WHENEVER SQLERROR CONTINUE

PROMPT Done!
PROMPT
SPOOL OFF
