declare
  e constant All_Editions.Edition_Name%type not null :=
    Sys_Context('Userenv', 'Session_Edition_Name');
begin
  p('Session_Edition is '||e);
end;
/
