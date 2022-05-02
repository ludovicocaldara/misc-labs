-- hr.000003.employee_add_columns.sql
alter session set DDL_LOCK_TIMEOUT=30;

alter table employees$0 add (
    country_code varchar2(3),
    phone# varchar2(20)
);

COMMENT ON COLUMN employees$0.country_code IS
'Telephone country code, e.g. +1 or +44';

COMMENT ON COLUMN employees$0.phone# IS
'Telephone number without country code';
