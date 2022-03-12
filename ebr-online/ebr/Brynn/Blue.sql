DISCONNECT
CLEAR SCREEN
VARIABLE Stmt VARCHAR2(4000)
SPOOL Blue.txt
WHENEVER SQLERROR EXIT
@@Connect_As_Usr
COLUMN Edition_Name FORMAT A12
COLUMN Object_Name FORMAT A11

PROMPT Application artifacts starting state
PROMPT
@Show_Application_Artifacts
PROMPT
PROMPT ................................................................................

PROMPT
@@Set_Edition_To_Old_Edition
PROMPT Ready to start.
PROMPT
PROMPT

@@Wait_Blue
CLEAR SCREEN
PROMPT 1. Starting the EBR exercise.
PROMPT
PROMPT
EXECUTE :Stmt := e.Create_Edition_e1()
@Execute_Sql
PROMPT
@@Set_Edition_To_New_Edition
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 3. Add the wide column to table t_.
PROMPT
PROMPT Notice the expected hang.
PROMPT
EXECUTE :Stmt := e.Alter_Table_t_Add_c_Wide()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 6. Creating unique index (online) on the new column.
PROMPT
PROMPT Notice the expected hang.
PROMPT
EXECUTE :Stmt := e.Create_Index_t_c_Wide_Unq()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 9. Add unique constraint (online) using the new unique index.
PROMPT
PROMPT Notice the expected hang.
PROMPT
EXECUTE :Stmt := e.Add_Cnstrnt_t_c_Wide_Unq()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 12. Validate the unique constraint.
PROMPT
PROMPT Insensitive to pending DML.
PROMPT
EXECUTE :Stmt := e.Validate_Cnstrnt_t_c_Wide_Unq()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 15. Redefine EV. Create Fwd CET. Wait on pending DML to enable.
PROMPT
EXECUTE :Stmt := e.Redefine_EV()
@Execute_Sql
PROMPT
EXECUTE :Stmt := e.Create_Fwd_CET()
@Execute_Sql
PROMPT
EXECUTE :Stmt := e.Enable_Fwd_CET()
@Execute_Sql
PROMPT
PROMPT Notice the "wait on pending DML".

EXECUTE :Stmt := e.Wait_On_Pending_DML()
@Execute_Sql
PROMPT
PROMPT CET can be trusted now.
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 18. Apply xform. Enable NN constraint novalidate.

EXECUTE :Stmt := e.Apply_Xform()
@Execute_Sql
PROMPT
PROMPT Notice the expected hang.
PROMPT
EXECUTE :Stmt := e.Create_Cnstrnt_t_c_Wide_NN()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 21. Validate NN constraint. Create reverse CET.

PROMPT
PROMPT Insensitive to pending DML.
PROMPT
EXECUTE :Stmt := e.Validate_Cnstrnt_t_c_Wide_NN()
@Execute_Sql
PROMPT
EXECUTE :Stmt := e.Alter_View_v_Compile()
@Execute_Sql
PROMPT
EXECUTE :Stmt := e.Create_Rvrs_CET()
@Execute_Sql
PROMPT
EXECUTE :Stmt := e.Enable_Rvrs_CET()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 24. Ready For Hot Rollover.
PROMPT
PROMPT Content of the base table t_:
PROMPT
@Show_Base_Table
PROMPT
PROMPT How many sessions are using the Run Edition and the Patch Edition?
PROMPT
call Show_Sessions_Per_Edition()
/
PROMPT
PROMPT Hot rollover can start now.
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 27. Hot rollover is complete.
PROMPT
PROMPT How many sessions are using the Run Edition and the Patch Edition?
PROMPT
call Show_Sessions_Per_Edition()
/

-- This is also legal syntax. Not useful here.
-- alter table t_ modify constraint t_c_NN disable novalidate.
PROMPT
PROMPT Notice the expected hang.
PROMPT
EXECUTE :Stmt := e.Drop_Cnstrnt_t_c_NN()
@Execute_Sql
PROMPT
PROMPT Drop the reverse and forward CETs.
PROMPT
EXECUTE :Stmt := e.Drop_Rvrs_CET()
@Execute_Sql
PROMPT
EXECUTE :Stmt := e.Drop_Fwd_CET()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 30. Drop the unique index on t_.c
PROMPT
PROMPT Notice the expected hang. ("online" is newly allowed in 12.1.)
PROMPT
EXECUTE :Stmt := e.Drop_Cnstrnt_t_c_Unq()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 33. Drop covered objects. Set c unused.
PROMPT
PROMPT Query User_Objects_AE for just editioned objects
PROMPT
@@Qry_User_Objects_AE
PROMPT
PROMPT Drop covered objects. Set c1 unused.
-- We know that the only editioned object in the old edition is the EV
-- For this exercise, we can just drop it explicitly
PROMPT
EXECUTE :Stmt := e.Drop_Covered_EV()
@Execute_Sql
PROMPT
PROMPT Re-query User_Objects_AE for just editioned objects
PROMPT
@@Qry_User_Objects_AE
PROMPT
PROMPT Notice the expected hang. ("online" is newly allowed in 12.1)
PROMPT
EXECUTE :Stmt := e.Set_c_Unused()
@Execute_Sql
PROMPT
@@Assert_All_Usr_Objects_Valid
PROMPT All objects confirmed to be valid.
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 36. Set the database default edition to the Patch edition.
PROMPT
EXECUTE :Stmt := e.Set_Default_Edition_e1()
@Execute_Sql
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 39. EBR Exercise is now complete!
PROMPT
PROMPT ................................................................................

@@Wait_Blue
CLEAR SCREEN
PROMPT 42. Final population of t
PROMPT
@@Show_EV
PROMPT
PROMPT Application artifacts state on completion of the EBR exercise
PROMPT
@Show_Application_Artifacts
PROMPT
PROMPT ................................................................................
WHENEVER SQLERROR CONTINUE
PROMPT
PROMPT
PROMPT Done!
PROMPT
SPOOL OFF
