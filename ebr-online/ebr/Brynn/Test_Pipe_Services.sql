-- In the TINY window
CLEAR SCREEN
@@Install_EBR_Readied_App

--------------------------------------------------------------------------------
-- In the BLUE window
CLEAR SCREEN
@@Connect_As_Usr
call Usr.Pipe_Services.Wait_Blue()
/
DISCONNECT

--------------------------------------------------------------------------------
-- In the RED window
CLEAR SCREEN
@@Connect_As_Usr
call Usr.Pipe_Services.Wait_Red()
/
DISCONNECT

--------------------------------------------------------------------------------
-- In the GREEN window
CLEAR SCREEN
@@Connect_As_Usr
call Usr.Pipe_Services.Wait_Green()
/
DISCONNECT

--------------------------------------------------------------------------------
-- In the TINY window
CLEAR SCREEN
@@Connect_As_Sys

call Usr.Pipe_Services.Continue_Blue()
/
call Usr.Pipe_Services.Continue_Red()
/
call Usr.Pipe_Services.Continue_Green()
/
DISCONNECT
