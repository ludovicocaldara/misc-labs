DISCONNECT
CLEAR SCREEN
SPOOL Fresh_Start.txt
WHENEVER SQLERROR EXIT

@@Connect_As_Sys
-- Sometimes "drop user cascade" fails w/ incomplete index.
call x.Drop_Object('t', 'Usr')
/
call x.Drop_User('Usr')
/
call x.Prep_To_Drop_All_But_Curr_Root()
/
call x.Kill_Sessions_Using_Other_Edns()
/
call x.Drop_All_Edns_But_Curr_Root()
/
@@Cr_Usr
@@Cr_p
@@Cr_Pipe_Services
@@Create_Pipes
@@Cr_Show_Sessions_Per_Edition
@@Cr_EBR_Exercise_Statements

@@Connect_As_Usr
@@Set_Edition_To_Old_Edition
@@Install_EBR_Readied_App

@@Connect_As_Sys

PROMPT Ready to start the demo.
PROMPT
PROMPT
WHENEVER SQLERROR CONTINUE
SPOOL OFF
