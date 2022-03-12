alter system flush Shared_Pool
/
/
/
/
/

declare
  procedure Create_Pipe(p in varchar2) is
    Status constant integer not null := DBMS_Pipe.Create_Pipe(
                        PipeName    => p,
                        MaxPipeSize => 1024,
                        Private     => false);
  begin
    DBMS_Pipe.Purge(PipeName=>p);
    if Status <> 0 then raise Program_Error; end if;
  end Create_Pipe;
begin
  for j in 1..Usr.Pipe_Services.Pipes.Count() loop
    Create_Pipe(Usr.Pipe_Services.Pipes(j));
  end loop;
end;
/

COLUMN Pipe_Name FORMAT A20
COLUMN Ownerid   FORMAT 99999
COLUMN Type      FORMAT A7
COLUMN Pipe_Size FORMAT 99999999
select Name Pipe_Name , Nvl(Ownerid, -99999) Ownerid, Type, Pipe_Size
from v$DB_Pipes
order by 1, 2, 3
/
