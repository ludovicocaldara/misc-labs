CLEAR SCREEN
CONNECT Sys/oracle@x/r12102 AS SYSDBA
grant Create Session to Usr identified by p
/
drop user Usr cascade
/
grant
  Create Session,
  Unlimited Tablespace,
  Create Table,
  Create Sequence,
  Create Trigger
to Usr identified by p
/
CONNECT Usr/p@x/r12102
--------------------------------------------------------------------------------
create table t_(c  varchar2(10))
/

create table t(
  PK integer generated always as identity,
  c  varchar2(50))
/
alter table t add constraint t_PK primary key(PK)
/
alter table t modify c constraint c_NN not null
/
create unique index t_c_Unq on t(c) online
/
alter table t modify c constraint t_c_Unq unique using index
/

-- Note: this is a blocking DDL. So Best done at EBR-readying time.
alter table t enable row movement
/
--------------------------------------------------------------------------------

create trigger Rvrs
before insert or update on t for each row
begin
  insert into t_(c) values(:New.c);
end Rvrs;
/
insert into t(c) values('dog')
/
select c from t_
/
insert into t(c) values('12345678901')
/
drop trigger Rvrs
/
insert into t(c) values('12345678901')
/
select c from t
/
