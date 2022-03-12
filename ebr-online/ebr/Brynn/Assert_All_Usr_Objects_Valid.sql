call Sys.Utl_Recomp.Recomp_Serial()
/
declare
  s User_Objects.Status%type := null;
  Msg constant varchar(32767) not null := 'Not all of Usr''s objects are valid';
begin
  select distinct Status
  into s
  from User_Objects;
  if s <> 'VALID' then
    Raise_Application_Error(-20000, Msg);
  end if;
exception when Too_Many_Rows then
  Raise_Application_Error(-20000, Msg);
end;
/
