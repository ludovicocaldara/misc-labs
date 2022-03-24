DECLARE
  scn number := null;
  -- A null or negative value for Timeout will cause a very long wait.
  timeout constant integer := null;

BEGIN
  if not sys.dbms_utility.wait_on_pending_dml(
    tables => 'EMPLOYEES$0',
    timeout => timeout,
    scn => scn)
  then
    raise_application_error(-20000,
      'wait_on_pending_dml() timed out. '||
      'CET was enabled before SCN: '||SCN
    );
  end if;
end;
/
