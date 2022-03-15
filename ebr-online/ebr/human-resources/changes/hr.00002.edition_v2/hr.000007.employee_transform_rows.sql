declare
  cur integer := sys.dbms_sql.open_cursor(security_level => 2);
  no_of_updated_rows integer not null := -1;
begin
  sys.dbms_sql.parse(
    c => cur,
    language_flag => sys.dbms_sql.native,
    statement => 'update employees$0 set phone_number = phone_number',
    apply_crossedition_trigger => 'employees_fwdxedition_trg',
    fire_apply_trigger => true
  );
  no_of_updated_rows := sys.dbms_sql.execute(cur);
  sys.dbms_sql.close_cursor(cur);
end;
/
