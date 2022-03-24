begin
  dbms_redefinition.finish_redef_table ( user, 'EMPLOYEES$0', 'EMPLOYEES$INTERIM');

  dbms_utility.compile_schema(schema => user, compile_all => FALSE);
end;
/
