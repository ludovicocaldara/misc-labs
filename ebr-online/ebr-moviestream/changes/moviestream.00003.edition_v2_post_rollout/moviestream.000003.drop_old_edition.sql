-- moviestream.000003.drop_old_edition.sql
declare
  l_parent_edition dba_editions.edition_name%type;
begin
  select  PARENT_EDITION_NAME into l_parent_edition
    from dba_editions where edition_name='V2';
  admin.drop_edition(l_parent_edition);
end;
/
