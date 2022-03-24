rem
rem Header: hr_main.sql 2015/03/19 10:23:26 smtaylor Exp $
rem
rem Copyright (c) 2001, 2015, Oracle and/or its affiliates.  All rights reserved. 
rem 
rem Permission is hereby granted, free of charge, to any person obtaining
rem a copy of this software and associated documentation files (the
rem "Software"), to deal in the Software without restriction, including
rem without limitation the rights to use, copy, modify, merge, publish,
rem distribute, sublicense, and/or sell copies of the Software, and to
rem permit persons to whom the Software is furnished to do so, subject to
rem the following conditions:
rem 
rem The above copyright notice and this permission notice shall be
rem included in all copies or substantial portions of the Software.
rem 
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
rem EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
rem MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
rem NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
rem LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
rem OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
rem WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
rem
rem Owner  : ahunold
rem
rem NAME
rem   hr_main.sql - Main script for HR schema
rem
rem DESCRIPTON
rem   HR (Human Resources) is the smallest and most simple one 
rem   of the Sample Schemas
rem   
rem NOTES
rem   Run as SYS or SYSTEM
rem
rem MODIFIED   (MM/DD/YY)
Rem   lcaldara    03/13/22 - Added editioning views for EBR
rem   smtaylor  03/19/15 - added parameter 6, connect_string
rem   smtaylor  03/19/15 - added @&connect_string to CONNECT
rem   jmadduku  02/18/11 - Grant Unlimited Tablespace priv with RESOURCE
rem   celsbern  06/17/10 - fixing bug 9733839
rem   pthornto  07/16/04 - obsolete 'connect' role 
rem   hyeh      08/29/02 - hyeh_mv_comschema_to_rdbms
rem   ahunold   08/28/01 - roles
rem   ahunold   07/13/01 - NLS Territory
rem   ahunold   04/13/01 - parameter 5, notes, spool
rem   ahunold   03/29/01 - spool
rem   ahunold   03/12/01 - prompts
rem   ahunold   03/07/01 - hr_analz.sql
rem   ahunold   03/03/01 - HR simplification, REGIONS table
rem   ngreenbe  06/01/00 - created

SET ECHO OFF
SET VERIFY OFF

PROMPT 
PROMPT specify password for HR as parameter 1:
DEFINE pass     = &1
PROMPT 
PROMPT specify default tablespeace for HR as parameter 2:
DEFINE tbs      = &2
PROMPT 
PROMPT specify temporary tablespace for HR as parameter 3:
DEFINE ttbs     = &3
PROMPT 
PROMPT specify log path as parameter 5:
DEFINE log_path = &5
PROMPT
PROMPT specify connect string as parameter 6:
DEFINE connect_string     = &6
PROMPT

-- The first dot in the spool command below is 
-- the SQL*Plus concatenation character

DEFINE spool_file = &log_path.hr_main.log
SPOOL &spool_file

REM =======================================================
REM cleanup section
REM =======================================================

declare
  e_user_exists exception;
  pragma exception_init (e_user_exists, -1918);
begin
  begin
    execute immediate 'drop user hr cascade';
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
REM create user
REM three separate commands, so the create user command 
REM will succeed regardless of the existence of the 
REM DEMO and TEMP tablespaces 
REM =======================================================

CREATE USER hr IDENTIFIED BY &pass;

ALTER USER hr DEFAULT TABLESPACE &tbs
              QUOTA UNLIMITED ON &tbs;

ALTER USER hr TEMPORARY TABLESPACE &ttbs;

GRANT CREATE SESSION, CREATE VIEW, ALTER SESSION, CREATE SEQUENCE TO hr;
GRANT CREATE SYNONYM, CREATE DATABASE LINK, RESOURCE , UNLIMITED TABLESPACE TO hr;

-- for using the editions
ALTER USER hr ENABLE EDITIONS;
grant select on dba_editions to hr;


-- for using DBMS_REDEFINITION
GRANT CREATE MATERIALIZED VIEW TO HR;
GRANT EXECUTE ON DBMS_REDEFINITION TO HR;

-- grant to the helper procedures
grant execute on create_edition to hr;
grant execute on drop_edition to hr;
grant execute on default_edition to hr;


REM =======================================================
REM create hr schema objects
REM =======================================================

CONNECT hr/&pass@&connect_string
ALTER SESSION SET NLS_LANGUAGE=American;
ALTER SESSION SET NLS_TERRITORY=America;

--
-- create tables, sequences and constraint
--

@hr_cre

-- 
-- populate tables
--

@hr_popul

--
-- create indexes
--

@hr_idx

--
-- create procedural objects
--

@hr_code

--
-- add comments to tables and columns
--

@hr_comnt

--
-- gather schema statistics
--

@hr_analz

spool off
