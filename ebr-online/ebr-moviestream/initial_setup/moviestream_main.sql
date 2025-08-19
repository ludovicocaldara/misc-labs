rem NAME
rem   moviestream_main.sql - Main script for MOVIESTREAM schema
rem
rem DESCRIPTON
rem   MOVIESTREAM contains example data for the MovieStream application
rem   used for Autonomous Data Warehouse LiveLabs
rem   
rem NOTES
rem   Run as ADMIN on ADB (ATP or ADW)
rem
rem   lcaldara  01/04/23 - created

SET ECHO OFF
SET VERIFY OFF

PROMPT 
PROMPT specify password for MOVIESTREAM as parameter 1:
DEFINE pass     = &1
PROMPT 
PROMPT specify log path as parameter 5:
DEFINE log_path = &2
PROMPT
PROMPT specify connect string as parameter 6:
DEFINE connect_string     = &3
PROMPT

-- The first dot in the spool command below is 
-- the SQL*Plus concatenation character

DEFINE spool_file = &log_path.moviestream_main.log
SPOOL &spool_file

REM =======================================================
REM cleanup section
REM =======================================================

declare
  e_user_exists exception;
  pragma exception_init (e_user_exists, -1918);
begin
  begin
    execute immediate 'drop user moviestream cascade';
  exception
    when e_user_exists then null;
  end;
end;
/


REM ======================================================
REM procedure to create editions as ADMIN (with AUTHID definer) and grant to invoker
REM ======================================================
create or replace procedure create_edition (edition_name varchar2)
   authid definer
as 
  e_edition_exists exception;
  e_grant_to_self exception;
  pragma exception_init (e_edition_exists, -955);
  pragma exception_init (e_grant_to_self, -1749);
begin
  begin
    execute immediate 'CREATE EDITION '||edition_name;
  exception
    when e_edition_exists then null;
  end;
  begin
    execute immediate 'GRANT USE ON EDITION '||edition_name||' TO '||USER;
  exception
    when e_grant_to_self then null;
  end;
end;
/

REM ======================================================
REM procedure to drop editions as ADMIN (with AUTHID definer)
REM ======================================================
create or replace procedure drop_edition (edition_name varchar2)
   authid definer
as
  e_inexistent_edition exception;
  e_grant_to_self exception;
  e_not_granted exception;
  pragma exception_init (e_inexistent_edition, -38801);
  pragma exception_init (e_grant_to_self, -1749);
  pragma exception_init (e_not_granted, -1927);
begin

  begin
    execute immediate 'REVOKE USE ON EDITION '||edition_name||' FROM '||USER;
  exception
    when e_grant_to_self then null;
	when e_not_granted then null;
  end;
  begin
    execute immediate 'DROP EDITION '||edition_name||' CASCADE';
  exception
     when e_inexistent_edition then null;
  end;
  dbms_editions_utilities.clean_unusable_editions;
end;
/

REM ======================================================
REM procedure to set the default edition as ADMIN (with AUTHID definer)
REM ======================================================
create or replace procedure default_edition (edition_name varchar2)
   authid definer
as
begin
  execute immediate 'alter database default edition ='||edition_name;
end;
/



REM =======================================================
REM create user MOVIESTREAM
REM =======================================================

-- USER SQL
CREATE USER MOVIESTREAM IDENTIFIED BY &pass;

-- ADD ROLES
GRANT CONNECT TO MOVIESTREAM;
GRANT CONSOLE_DEVELOPER TO MOVIESTREAM;
GRANT GRAPH_DEVELOPER TO MOVIESTREAM;
GRANT RESOURCE TO MOVIESTREAM;
GRANT DWROLE TO MOVIESTREAM;
GRANT OML_DEVELOPER TO MOVIESTREAM;
ALTER USER MOVIESTREAM DEFAULT ROLE CONNECT,CONSOLE_DEVELOPER,GRAPH_DEVELOPER,RESOURCE;

-- ENABLE GRAPH and OML
alter user moviestream grant connect through OML$PROXY;
ALTER USER MOVIESTREAM GRANT CONNECT THROUGH GRAPH$PROXY_USER;

-- ENABLE REST
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled => TRUE,
        p_schema => 'MOVIESTREAM',
        p_url_mapping_type => 'BASE_PATH',
        p_url_mapping_pattern => 'moviestream',
        p_auto_rest_auth=> TRUE
    );
    commit;
END;
/

-- Allow user to change resource privileges (LOW/MEDIUM/HIGH)
grant select on v$services to moviestream;
grant select on dba_rsrc_consumer_group_privs to moviestream;
grant execute on dbms_session to moviestream;

-- QUOTA
ALTER USER MOVIESTREAM QUOTA UNLIMITED ON DATA;

-- for using the editions
ALTER USER moviestream ENABLE EDITIONS;
grant select on dba_editions to moviestream;

-- for using DBMS_REDEFINITION
GRANT CREATE MATERIALIZED VIEW TO moviestream;
GRANT EXECUTE ON DBMS_REDEFINITION TO moviestream;

-- grant to the helper procedures form EBR
grant execute on create_edition to moviestream;
grant execute on drop_edition to moviestream;
grant execute on default_edition to moviestream;
REM =======================================================
REM declare external data for moviestream tables
REM =======================================================
declare
    l_git varchar2(4000);
    l_repo_name varchar2(100) := 'livelabs-common';
    l_owner varchar2(100) := 'lcaldara-oracle';
    l_package_file varchar2(200) := 'building-blocks/setup/workshop-setup.sql';
    l_package_file2 varchar2(200) := 'building-blocks/setup/workshop-package.sql';
begin
    -- get a handle to github
    l_git := dbms_cloud_repo.init_github_repo(
                repo_name       => l_repo_name,
                owner           => l_owner );

    -- install the package header
    dbms_cloud_repo.install_file(
        repo        => l_git,
        file_path   => l_package_file,
        stop_on_error => false);

    dbms_cloud_repo.install_file(
        repo        => l_git,
        file_path   => l_package_file2,
        stop_on_error => false);

end;
/

grant execute on workshop to moviestream;

connect moviestream/&pass@&connect_string
exec admin.workshop.add_dataset('ALL');

-- the indexes were missing
CREATE INDEX MOVIESTREAM_IDX_CUSTSALES_FK_CUSTSALES_CUST_ID ON MOVIESTREAM.CUSTSALES (CUST_ID);
CREATE INDEX MOVIESTREAM_IDX_CUSTSALES_FK_CUSTSALES_GENRE_ID ON MOVIESTREAM.CUSTSALES (GENRE_ID);
CREATE INDEX MOVIESTREAM_IDX_CUSTSALES_FK_CUSTSALES_MOVIE_ID ON MOVIESTREAM.CUSTSALES (MOVIE_ID);
CREATE INDEX MOVIESTREAM_IDX_CUSTSALES_PROMOTIONS_FK_CUSTSALES_PROMOTIONS_CUST_ID ON MOVIESTREAM.CUSTSALES_PROMOTIONS (PROMO_CUST_ID);
CREATE INDEX MOVIESTREAM_IDX_CUSTSALES_PROMOTIONS_FK_CUSTSALES_PROMOTIONS_MOVIE_ID ON MOVIESTREAM.CUSTSALES_PROMOTIONS (MOVIE_ID);

ALTER TABLE PIZZA_LOCATION RENAME TO PIZZA_LOCATION$0;
ALTER TABLE CUSTOMER_SEGMENT RENAME TO CUSTOMER_SEGMENT$0;
ALTER TABLE CUSTOMER_PROMOTIONS RENAME TO CUSTOMER_PROMOTIONS$0;
ALTER TABLE CUSTOMER_CONTACT RENAME TO CUSTOMER_CONTACT$0;
ALTER TABLE MOVIESTREAM_CHURN RENAME TO MOVIESTREAM_CHURN$0;
ALTER TABLE GENRE RENAME TO GENRE$0;
ALTER TABLE CUSTOMER_EXTENSION RENAME TO CUSTOMER_EXTENSION$0;
ALTER TABLE CUSTSALES RENAME TO CUSTSALES$0;
ALTER TABLE TIME RENAME TO TIME$0;
ALTER TABLE CUSTOMER RENAME TO CUSTOMER$0;
ALTER TABLE MOVIE RENAME TO MOVIE$0;
ALTER TABLE CUSTSALES_PROMOTIONS RENAME TO CUSTSALES_PROMOTIONS$0;

CREATE EDITIONING VIEW PIZZA_LOCATION AS
   SELECT
      PIZZA_LOC_ID , LAT , LON , CHAIN_ID , CHAIN,
      ADDRESS , CITY , STATE , POSTAL_CODE , COUNTY
     FROM
      PIZZA_LOCATION$0;

CREATE EDITIONING VIEW CUSTOMER_SEGMENT AS
   SELECT
      SEGMENT_ID , NAME , SHORT_NAME
     FROM
      CUSTOMER_SEGMENT$0;

CREATE EDITIONING VIEW CUSTOMER_PROMOTIONS AS
   SELECT
      CUST_ID , LAST_NAME , FIRST_NAME , EMAIL , STREET_ADDRESS ,
      POSTAL_CODE , CITY , STATE_PROVINCE , COUNTRY , COUNTRY_CODE ,
      CONTINENT , YRS_CUSTOMER , PROMOTION_RESPONSE , LOC_LAT ,
      LOC_LONG , AGE , COMMUTE_DISTANCE , CREDIT_BALANCE ,
      EDUCATION , FULL_TIME , GENDER , HOUSEHOLD_SIZE , INCOME ,
      INCOME_LEVEL , INSUFF_FUNDS_INCIDENTS , JOB_TYPE ,
      LATE_MORT_RENT_PMTS , MARITAL_STATUS , MORTGAGE_AMT ,
      NUM_CARS , NUM_MORTGAGES , PET , RENT_OWN , SEGMENT_ID ,
      WORK_EXPERIENCE , YRS_CURRENT_EMPLOYER , YRS_RESIDENCE
     FROM
      CUSTOMER_PROMOTIONS$0;

CREATE EDITIONING VIEW CUSTOMER_CONTACT AS
   SELECT
      CUST_ID
    , LAST_NAME
    , FIRST_NAME
    , EMAIL
    , STREET_ADDRESS
    , POSTAL_CODE
    , CITY
    , STATE_PROVINCE
    , COUNTRY
    , COUNTRY_CODE
    , CONTINENT
    , YRS_CUSTOMER
    , PROMOTION_RESPONSE
    , LOC_LAT
    , LOC_LONG
     FROM
      CUSTOMER_CONTACT$0;

CREATE EDITIONING VIEW MOVIESTREAM_CHURN AS
   SELECT
      IS_CHURNER
    , AGE
    , CITY
    , CREDIT_BALANCE
    , EDUCATION
    , EMAIL
    , FIRST_NAME
    , GENDER
    , HOUSEHOLD_SIZE
    , INCOME_LEVEL
    , JOB_TYPE
    , LAST_NAME
    , LOC_LAT
    , LOC_LONG
    , MARITAL_STATUS
    , YRS_CUSTOMER
    , YRS_RESIDENCE
    , GENRE_ACTION
    , GENRE_ADVENTURE
    , GENRE_ANIMATION
    , GENRE_BIOGRAPHY
    , GENRE_COMEDY
    , GENRE_CRIME
    , GENRE_DOCUMENTARY
    , GENRE_DRAMA
    , GENRE_FAMILY
    , GENRE_FANTASY
    , GENRE_FILM_NOIR
    , GENRE_HISTORY
    , GENRE_HORROR
    , GENRE_MUSICAL
    , GENRE_MYSTERY
    , GENRE_NEWS
    , GENRE_REALITY_TV
    , GENRE_ROMANCE
    , GENRE_SCI_FI
    , GENRE_SPORT
    , GENRE_THRILLER
    , GENRE_WAR
    , GENRE_WESTERN
    , AGG_NTRANS_M3
    , AGG_NTRANS_M4
    , AGG_NTRANS_M5
    , AGG_NTRANS_M6
    , AGG_SALES_M3
    , AGG_SALES_M4
    , AGG_SALES_M5
    , AGG_SALES_M6
    , AVG_DISC_M3
    , AVG_DISC_M3_11
    , AVG_DISC_M3_5
    , AVG_NTRANS_M3_5
    , AVG_SALES_M3_5
    , DISC_PCT_DIF_M3_5_M6_11
    , DISC_PCT_DIF_M3_5_M6_8
    , SALES_PCT_DIF_M3_5_M6_8
    , TRANS_PCT_DIF_M3_5_M6_8
     FROM
      MOVIESTREAM_CHURN$0;

CREATE EDITIONING VIEW GENRE AS
   SELECT
      GENRE_ID
    , NAME
     FROM
      GENRE$0;

CREATE EDITIONING VIEW CUSTOMER_EXTENSION AS
   SELECT
      CUST_ID
    , LAST_NAME
    , FIRST_NAME
    , EMAIL
    , AGE
    , COMMUTE_DISTANCE
    , CREDIT_BALANCE
    , EDUCATION
    , FULL_TIME
    , GENDER
    , HOUSEHOLD_SIZE
    , INCOME
    , INCOME_LEVEL
    , INSUFF_FUNDS_INCIDENTS
    , JOB_TYPE
    , LATE_MORT_RENT_PMTS
    , MARITAL_STATUS
    , MORTGAGE_AMT
    , NUM_CARS
    , NUM_MORTGAGES
    , PET
    , RENT_OWN
    , SEGMENT_ID
    , WORK_EXPERIENCE
    , YRS_CURRENT_EMPLOYER
    , YRS_RESIDENCE
     FROM
      CUSTOMER_EXTENSION$0;

CREATE EDITIONING VIEW CUSTSALES AS
   SELECT
      DAY_ID
    , GENRE_ID
    , MOVIE_ID
    , CUST_ID
    , APP
    , DEVICE
    , OS
    , PAYMENT_METHOD
    , LIST_PRICE
    , DISCOUNT_TYPE
    , DISCOUNT_PERCENT
    , ACTUAL_PRICE
     FROM
      CUSTSALES$0;

CREATE EDITIONING VIEW TIME AS
   SELECT
      DAY_ID
    , DAY_NAME
    , DAY_OF_WEEK
    , DAY_OF_MONTH
    , DAY_OF_YEAR
    , WEEK_OF_MONTH
    , WEEK_OF_YEAR
    , MONTH_OF_YEAR
    , MONTH_NAME
    , MONTH_SHORT_NAME
    , QUARTER_NAME
    , QUARTER_OF_YEAR
    , YEAR_NAME
     FROM
      TIME$0;

CREATE OR REPLACE EDITIONING VIEW CUSTOMER AS
   SELECT
      CUST_ID , LAST_NAME , FIRST_NAME , EMAIL , STREET_ADDRESS ,
      POSTAL_CODE , CITY , STATE_PROVINCE , COUNTRY , COUNTRY_CODE ,
      CONTINENT , YRS_CUSTOMER , PROMOTION_RESPONSE , LOC_LAT ,
      LOC_LONG , AGE , COMMUTE_DISTANCE , CREDIT_BALANCE , EDUCATION ,
      FULL_TIME , GENDER , HOUSEHOLD_SIZE , INCOME , INCOME_LEVEL ,
      INSUFF_FUNDS_INCIDENTS , JOB_TYPE , LATE_MORT_RENT_PMTS ,
      MARITAL_STATUS , MORTGAGE_AMT , NUM_CARS , NUM_MORTGAGES ,
      PET , RENT_OWN , SEGMENT_ID , WORK_EXPERIENCE ,
      YRS_CURRENT_EMPLOYER , YRS_RESIDENCE
     FROM
      CUSTOMER$0;

CREATE EDITIONING VIEW MOVIE AS
   SELECT
      MOVIE_ID
    , TITLE
    , BUDGET
    , GROSS
    , LIST_PRICE
    , GENRES
    , SKU
    , YEAR
    , OPENING_DATE
    , VIEWS
    , CAST
    , CREW
    , STUDIO
    , MAIN_SUBJECT
    , AWARDS
    , NOMINATIONS
    , RUNTIME
    , SUMMARY
     FROM
      MOVIE$0;

CREATE EDITIONING VIEW CUSTSALES_PROMOTIONS AS
   SELECT
      DAY_ID
    , GENRE_ID
    , MOVIE_ID
    , CUST_ID
    , APP
    , DEVICE
    , OS
    , PAYMENT_METHOD
    , LIST_PRICE
    , DISCOUNT_TYPE
    , DISCOUNT_PERCENT
    , ACTUAL_PRICE
     FROM
      CUSTSALES_PROMOTIONS$0;


delete from CUSTSALES$0 where cust_id in (select cust_id from customer$0 where country_code='IT');
delete from customer$0 where country_code='IT';
commit;

spool off
