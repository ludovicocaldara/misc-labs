-- moviestream.000011.copy_dependents.sql
declare
  nerrors number;
begin
  dbms_redefinition.copy_table_dependents
    ( user, 'CUSTOMER$0', 'CUSTOMER$INTERIM',
      copy_indexes => dbms_redefinition.cons_orig_params,
      num_errors => nerrors );
  if nerrors > 0  then
    raise_application_error(-20000,'Errors in copying the dependents');
  end if;
end;
/
