create noneditionable package Usr.e authid Definer is
  function Create_Edition_e1 return varchar2;
  function Alter_Table_t_Add_c_Wide return varchar2;
  function Create_Index_t_c_Wide_Unq return varchar2;
  function Add_Cnstrnt_t_c_Wide_Unq return varchar2;
  function Validate_Cnstrnt_t_c_Wide_Unq return varchar2;
  function Redefine_EV return varchar2;
  function Create_Fwd_CET return varchar2;
  function Enable_Fwd_CET return varchar2;
  function Wait_On_Pending_DML return varchar2;
  function Apply_Xform return varchar2;
  function Create_Cnstrnt_t_c_Wide_NN return varchar2;
  function Validate_Cnstrnt_t_c_Wide_NN return varchar2;
  function Alter_View_v_Compile return varchar2;
  function Create_Rvrs_CET return varchar2;
  function Enable_Rvrs_CET return varchar2;
  function Set_Default_Edition_e1 return varchar2;
  function Drop_Cnstrnt_t_c_NN return varchar2;
  function Drop_Rvrs_CET return varchar2;
  function Drop_Fwd_CET return varchar2;
  function Drop_Cnstrnt_t_c_Unq return varchar2;
  function Drop_Covered_EV return varchar2;
  function Set_c_Unused return varchar2;
end e;
/
create package body Usr.e is
  function Create_Edition_e1 return varchar2 is
  begin
    return '
create edition e1 as child of Ora$Base';
  end Create_Edition_e1;

  ----------------------------------------------------------------------------------------

  function Alter_Table_t_Add_c_Wide return varchar2 is
  begin
    return '
alter table t_
add c_Wide varchar2(50)';
  end Alter_Table_t_Add_c_Wide;

  ----------------------------------------------------------------------------------------

  function Create_Index_t_c_Wide_Unq return varchar2 is
  begin
    return '
create unique index t_c_Wide_Unq
on t_(c_Wide)
online';
  end Create_Index_t_c_Wide_Unq;

  ----------------------------------------------------------------------------------------

  function Add_Cnstrnt_t_c_Wide_Unq return varchar2 is
  begin
    return '
alter table t_
add constraint t_c_Wide_Unq unique (c_Wide)
using index t_c_Wide_Unq
enable novalidate';
  end Add_Cnstrnt_t_c_Wide_Unq;

  ----------------------------------------------------------------------------------------

  function Validate_Cnstrnt_t_c_Wide_Unq return varchar2 is
  begin
    return '
alter table t_
enable validate
constraint t_c_Wide_Unq';

  end Validate_Cnstrnt_t_c_Wide_Unq;

  ----------------------------------------------------------------------------------------

  function Redefine_EV return varchar2 is
  begin
    return '
create or replace editioning view t as
select PK, c_Wide c from t_';
  end Redefine_EV;

  ----------------------------------------------------------------------------------------

  function Create_Fwd_CET return varchar2 is
  begin
    return q'{
create trigger Fwd
before update or insert on t_ for each row
forward crossedition
disable
begin
  :New.c_Wide := :new.c;
end Fwd;}';
  end Create_Fwd_CET;

  ----------------------------------------------------------------------------------------

  function Enable_Fwd_CET return varchar2 is
  begin
    return '
alter trigger Fwd enable';
  end Enable_Fwd_CET;

  ----------------------------------------------------------------------------------------

  function Wait_On_Pending_DML return varchar2 is
  begin
    return q'{
declare
  -- Supplying "null" for the SCN formal
  -- to Wait_On_Pending_DML() asks it to get
  -- the most current SCN across all instances.
  SCN number := null;

  -- A null or negative value for Timeout
  -- will cause a very long wait.
  Timeout constant integer := null;
begin
  if not DBMS_Utility.Wait_On_Pending_DML(
    Tables  => 't_',
    Timeout => Timeout,
    SCN     => SCN)
  then
    Raise_Application_Error(-20000,
     'Wait_On_Pending_DML() timed out. '||
     'CET was enabled before SCN: '||SCN);
  end if;
end Wait_On_Pending_DML;}';
  end Wait_On_Pending_DML;

  ----------------------------------------------------------------------------------------

  function Apply_Xform return varchar2 is
  begin
    return q'{
declare
  Cur integer := DBMS_Sql.Open_Cursor(Security_Level => 2);
  No_Of_Updated_Rows integer not null := -1;
begin
  DBMS_Sql.Parse(
    c                          => Cur,
    Language_Flag              => DBMS_Sql.Native,
    Statement                  => 'update t_ set c = c',
    Apply_Crossedition_Trigger => 'Fwd',
    Fire_Apply_Trigger         => true);

  No_Of_Updated_Rows := DBMS_Sql.Execute(Cur);
  DBMS_Sql.Close_cursor(Cur);
end;}';
  end Apply_Xform;

  ----------------------------------------------------------------------------------------

  function Create_Cnstrnt_t_c_Wide_NN return varchar2 is
  begin
    return '
alter table t_
modify c_Wide constraint t_c_Wide_NN not null
enable novalidate';
  end Create_Cnstrnt_t_c_Wide_NN;

  ----------------------------------------------------------------------------------------

  function Validate_Cnstrnt_t_c_Wide_NN return varchar2 is
  begin
    return '
alter table t_
enable validate
constraint t_c_Wide_NN';
  end Validate_Cnstrnt_t_c_Wide_NN;

  ----------------------------------------------------------------------------------------

  function Alter_View_v_Compile return varchar2 is
  begin
    return '
alter view t compile';
  end Alter_View_v_Compile;

  ----------------------------------------------------------------------------------------

  function Create_Rvrs_CET return varchar2 is
  begin
    return q'{
create trigger Rvrs
before update or insert on t_ for each row
reverse crossedition
disable
begin
  :New.c := :new.c_Wide;
end Rvrs;}';
  end Create_Rvrs_CET;

  ----------------------------------------------------------------------------------------

  function Enable_Rvrs_CET return varchar2 is
  begin
    return '
alter trigger Rvrs enable';
  end Enable_Rvrs_CET;

  ----------------------------------------------------------------------------------------

  function Set_Default_Edition_e1 return varchar2 is
  begin
    return '
alter database default edition = e1';
  end Set_Default_Edition_e1;

  ----------------------------------------------------------------------------------------

  function Drop_Cnstrnt_t_c_NN return varchar2 is
  begin
    return '
alter table t_
drop constraint t_c_NN
online';
  end Drop_Cnstrnt_t_c_NN;

  ----------------------------------------------------------------------------------------

  function Drop_Rvrs_CET return varchar2 is
  begin
    return '
drop trigger Rvrs';
  end Drop_Rvrs_CET;

  ----------------------------------------------------------------------------------------

  function Drop_Fwd_CET return varchar2 is
  begin
    return '
drop trigger Fwd';
  end Drop_Fwd_CET;

  ----------------------------------------------------------------------------------------

  function Drop_Cnstrnt_t_c_Unq return varchar2 is
  begin
    return '
alter table t_
drop constraint t_c_Unq
online';
  end Drop_Cnstrnt_t_c_Unq;

  ----------------------------------------------------------------------------------------

  function Drop_Covered_EV return varchar2 is
  begin
    return q'{
declare
  Stmt constant varchar2(32767) not null := '
    drop view t';
  Cur integer := DBMS_Sql.Open_Cursor(Security_level=>2);
begin
  -- Parse for a DDL implies Execute.
  DBMS_Sql.Parse(
    c             => Cur,
    Language_Flag => DBMS_Sql.Native,
    Statement     => Stmt,
    Edition       => 'ORA$BASE');  
  DBMS_Sql.Close_Cursor(Cur);
end;}';
  end Drop_Covered_EV;

  ----------------------------------------------------------------------------------------

  function Set_c_Unused return varchar2 is
  begin
    return '
alter table t_
set unused column c
online';
  end Set_c_Unused;
end e;
/
