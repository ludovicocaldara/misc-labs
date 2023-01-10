-- moviestream.000012.finish_redef_table.sql
begin
  dbms_redefinition.finish_redef_table ( user, 'CUSTOMER$0', 'CUSTOMER$INTERIM');

  dbms_utility.compile_schema(schema => user, compile_all => FALSE);
end;
/
