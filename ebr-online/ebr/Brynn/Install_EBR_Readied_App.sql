-- Use the new-in-12.1 "identity" column
create table t_(
  PK integer generated always as identity,
  c  varchar2(10))
/
alter table t_ add constraint t_PK primary key(PK)
/
alter table t_ modify c constraint t_c_NN not null
/
create unique index t_c_Unq on t_(c) online
/
alter table t_ modify c constraint t_c_Unq unique using index
/

-- Note: this is a blocking DDL. So Best done at EBR-readying time.
alter table t_ enable row movement
/

create editioning view t as select PK, c from t_
/
begin
  insert into t(c) values('blue fish');
  commit;
end;
/
