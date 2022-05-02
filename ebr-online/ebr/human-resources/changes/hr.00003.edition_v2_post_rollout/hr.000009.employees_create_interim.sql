-- hr.000009.employees_create_interim.sql
create table employees$interim
    ( employee_id    NUMBER(6)
    , first_name     VARCHAR2(20)
    , last_name      VARCHAR2(25)   
    , email          VARCHAR2(25)   
	, country_code          VARCHAR2(3)   
    , phone#   VARCHAR2(20)
    , hire_date      DATE
    , job_id         VARCHAR2(10)
    , salary         NUMBER(8,2)
    , commission_pct NUMBER(2,2)
    , manager_id     NUMBER(6)
    , department_id  NUMBER(4)
    ) ;

