create noneditionable procedure Usr.p(Txt in varchar2) authid Definer is
begin
  Sys.DBMS_Output.Put_Line(Txt);
end p;
/
