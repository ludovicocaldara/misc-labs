call x.Drop_Object('Pipe_Services', 'Usr')
/
create noneditionable package Usr.Pipe_Services authid Definer is
  Wait_Blue_Pipe       constant varchar2(20) := 'WAIT_BLUE';
  Continue_Blue_Pipe   constant varchar2(20) := 'CONTINUE_BLUE';
  Wait_Red_Pipe        constant varchar2(20) := 'WAIT_RED';
  Continue_Red_Pipe    constant varchar2(20) := 'CONTINUE_RED';
  Wait_Green_Pipe      constant varchar2(20) := 'WAIT_GREEN';
  Continue_Green_Pipe  constant varchar2(20) := 'CONTINUE_GREEN';

  type t is table of varchar2(30);
  Pipes constant t not null := t(
    Wait_Blue_Pipe,
    Continue_Blue_Pipe,
    Wait_Red_Pipe,
    Continue_Red_Pipe,
    Wait_Green_Pipe,
    Continue_Green_Pipe);

  procedure Wait_Blue;
  procedure Continue_Blue;
  procedure Wait_Red;
  procedure Continue_Red;
  procedure Wait_Green;
  procedure Continue_Green;
end Pipe_Services;
/
SHOW ERRORS
create package body Usr.Pipe_Services is
  -- See use of Receive_Message() in the Wait* procedures.
  -- "Status = 0" means normal return.
  -- "Status = 1" means "timed out".
  -- We set Timeout_Seconds very small for certain demo scenarios.
  Timeout_Seconds constant integer not null := 5*60;

  -- Any arbitrary value.
  x constant pls_integer not null := 1234567;

  procedure Wait_Blue is
    Status integer not null := -1;
    Returned_x pls_integer not null := 0;
  begin
    DBMS_Pipe.Pack_Message(Item => x);
    Status := DBMS_Pipe.Send_Message(PipeName => Wait_Blue_Pipe);
    if Status <> 0 then Raise Program_Error; end if;

    Status := DBMS_Pipe.Receive_Message(PipeName => Continue_Blue_Pipe, Timeout => Timeout_Seconds);
    if Status = 0 then
      DBMS_Pipe.Unpack_Message(Item => Returned_x);
      if Returned_x <> x then raise Program_Error; end if;
      p('Continuing...');
    elsif Status = 1 then
      -- Avaoid ORA-06556: the pipe is empty, cannot fulfill the unpack_message request
      p('Continuing...');
    else
      Raise Program_Error;
    end if;
  end Wait_Blue;

  procedure Continue_Blue is
    Status integer not null := -1;
    Unpacked_x pls_integer not null := 0;
  begin
    Status := DBMS_Pipe.Receive_Message(PipeName => Wait_Blue_Pipe);
    DBMS_Pipe.Unpack_Message(Item => Unpacked_x);
    if Unpacked_x <> x then raise Program_Error; end if;

    DBMS_Pipe.Pack_Message(Item => x);
    Status := DBMS_Pipe.Send_Message(PipeName => Continue_Blue_Pipe);
    if Status <> 0 then Raise Program_Error; end if;
  end Continue_Blue;

  procedure Wait_Red is
    Status integer not null := -1;
    Returned_x pls_integer not null := 0;
  begin
    DBMS_Pipe.Pack_Message(Item => x);
    Status := DBMS_Pipe.Send_Message(PipeName => Wait_Red_Pipe);
    if Status <> 0 then Raise Program_Error; end if;

    Status := DBMS_Pipe.Receive_Message(PipeName => Continue_Red_Pipe, Timeout => Timeout_Seconds);
    if Status = 0 then
      DBMS_Pipe.Unpack_Message(Item => Returned_x);
      if Returned_x <> x then raise Program_Error; end if;
      p('Continuing...');
    elsif Status = 1 then
      -- Avaoid ORA-06556: the pipe is empty, cannot fulfill the unpack_message request
      p('Continuing...');
    else
      Raise Program_Error;
    end if;
  end Wait_Red;

  procedure Continue_Red is
    Status integer not null := -1;
    Unpacked_x pls_integer not null := 0;
  begin
    Status := DBMS_Pipe.Receive_Message(PipeName => Wait_Red_Pipe);
    DBMS_Pipe.Unpack_Message(Item => Unpacked_x);
    if Unpacked_x <> x then raise Program_Error; end if;

    DBMS_Pipe.Pack_Message(Item => x);
    Status := DBMS_Pipe.Send_Message(PipeName => Continue_Red_Pipe);
    if Status <> 0 then Raise Program_Error; end if;
  end Continue_Red;

  procedure Wait_Green is
    Status integer not null := -1;
    Returned_x pls_integer not null := 0;
  begin
    DBMS_Pipe.Pack_Message(Item => x);
    Status := DBMS_Pipe.Send_Message(PipeName => Wait_Green_Pipe);
    if Status <> 0 then Raise Program_Error; end if;

    Status := DBMS_Pipe.Receive_Message(PipeName => Continue_Green_Pipe, Timeout => Timeout_Seconds);
    if Status = 0 then
      DBMS_Pipe.Unpack_Message(Item => Returned_x);
      if Returned_x <> x then raise Program_Error; end if;
      p('Continuing...');
    elsif Status = 1 then
      -- Avaoid ORA-06556: the pipe is empty, cannot fulfill the unpack_message request
      p('Continuing...');
    else
      Raise Program_Error;
    end if;
  end Wait_Green;

  procedure Continue_Green is
    Status integer not null := -1;
    Unpacked_x pls_integer not null := 0;
  begin
    Status := DBMS_Pipe.Receive_Message(PipeName => Wait_Green_Pipe);
    DBMS_Pipe.Unpack_Message(Item => Unpacked_x);
    if Unpacked_x <> x then raise Program_Error; end if;

    DBMS_Pipe.Pack_Message(Item => x);
    Status := DBMS_Pipe.Send_Message(PipeName => Continue_Green_Pipe);
    if Status <> 0 then Raise Program_Error; end if;
  end Continue_Green;
end Pipe_Services;
/
SHOW ERRORS
