-- Set edition for self-documentation and to allow all scripts
-- to be run from single master script in one session for quick testing of
-- the ultimate result.
declare
  e constant All_Editions.Edition_Name%type not null :=
    Sys_Context('Userenv', 'Session_Edition_Name');
  Run_Edition constant All_Editions.Edition_Name%type not null := 'ORA$BASE';
begin
  if e <> Run_Edition then
    p('Setting edition...');
    DBMS_Session.Set_Edition_Deferred(Run_Edition);
  end if;
end;
/
@@Show_Session_Edition
