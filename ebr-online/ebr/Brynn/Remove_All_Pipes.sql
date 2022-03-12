alter system flush Shared_Pool
/
/
/
/
/

-- Bootstrap
grant Create Procedure to Usr identified by p
/
@@Cr_Pipe_Services

declare
  n integer not null := 99;

  procedure Remove_Pipe(p in varchar2) is
    Dummy integer not null := 99;
  begin
    DBMS_Pipe.Purge(PipeName=>p);
    Dummy := DBMS_Pipe.Remove_Pipe(PipeName => 'WAIT_BLUE');
    if Dummy <> 0 then raise Program_Error; end if;
  end Remove_Pipe;
begin
  for j in 1..Usr.Pipe_Services.Pipes.Count() loop
    Remove_Pipe(Usr.Pipe_Services.Pipes(j));
  end loop;

  -- Sometimes the pipe is left orphaned after
  -- the user that created it has been dropped.
  execute immediate 'alter system flush Shared_Pool';

  select Count(*) into n from v$DB_Pipes;
  if n <> 0 then raise Program_Error; end if;
end;
/
