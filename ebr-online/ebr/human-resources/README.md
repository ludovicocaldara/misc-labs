# Human Resources example with Edition-Based Redefinition

## Requirements
* The Autonomous Database created with the Terraform Stack in ../../terraform
* The wallet of the Autonomous Database saved in this directory as `adb_wallet.zip`
* A recent version of `SQLcl` (possibly >= 21.4)


## Install the base HR schema
```
$ cd misc-labs/ebr-online/ebr/human-resources/initial_setup
$ rlwrap sql /nolog

SQLcl: Release 21.4 Production on Mon Mar 14 15:18:04 2022

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

SQL> set cloudconfig ../../adb_wallet.zip
SQL> connect admin/*****@demoadb_medium
Connected.
SQL> @hr_main

specify password for HR as parameter 1:
Enter value for 1: Welcome#Welcome#123

specify default tablespeace for HR as parameter 2:
Enter value for 2: SAMPLESCHEMAS

specify temporary tablespace for HR as parameter 3:
Enter value for 3: TEMP

specify log path as parameter 5:
Enter value for 5: ./

specify connect string as parameter 6:
Enter value for 6: demoadb_medium

User HR dropped.

User HR created.

User HR altered.

User HR altered.

Grant succeeded.

Grant succeeded.

Grant succeeded.

User HR altered.
Connected.

Session altered.

Session altered.
******  Creating REGIONS table ....

Table REGIONS$0 created.

View REGIONS created.

INDEX REG_ID_PK created.

Table REGIONS$0 altered.
******  Creating COUNTRIES table ....

Table COUNTRIES$0 created.

View COUNTRIES created.

Table COUNTRIES$0 altered.
******  Creating LOCATIONS table ....

Table LOCATIONS$0 created.

View LOCATIONS created.

INDEX LOC_ID_PK created.

Table LOCATIONS$0 altered.

Sequence LOCATIONS_SEQ created.
******  Creating DEPARTMENTS table ....

Table DEPARTMENTS$0 created.

View DEPARTMENTS created.

INDEX DEPT_ID_PK created.

Table DEPARTMENTS$0 altered.

Sequence DEPARTMENTS_SEQ created.
******  Creating JOBS table ....

Table JOBS$0 created.

View JOBS created.

INDEX JOB_ID_PK created.

Table JOBS$0 altered.
******  Creating EMPLOYEES table ....

Table EMPLOYEES$0 created.

View EMPLOYEES created.

INDEX EMP_EMP_ID_PK created.

Table EMPLOYEES$0 altered.

Table DEPARTMENTS$0 altered.

Sequence EMPLOYEES_SEQ created.
******  Creating JOB_HISTORY table ....

Table JOB_HISTORY$0 created.

View JOB_HISTORY created.

INDEX JHIST_EMP_ID_ST_DATE_PK created.

Table JOB_HISTORY$0 altered.
******  Creating EMP_DETAILS_VIEW view ...

View EMP_DETAILS_VIEW created.

Commit complete.

Session altered.
******  Populating REGIONS table ....

1 row inserted.

******  Populating COUNTIRES table ....

1 row inserted.
[...]
1 row inserted.

******  Populating LOCATIONS table ....

1 row inserted.
[...]
1 row inserted.

******  Populating DEPARTMENTS table ....

Table DEPARTMENTS$0 altered.

1 row inserted.
[...]
1 row inserted.

******  Populating JOBS table ....

1 row inserted.
[...]
1 row inserted.

******  Populating EMPLOYEES table ....

1 row inserted.
[...]
1 row inserted.

******  Populating JOB_HISTORY table ....

1 row inserted.
[...]
1 row inserted.

Table DEPARTMENTS$0 altered.

Commit complete.

Index EMP_DEPARTMENT_IX created.

Index EMP_JOB_IX created.

Index EMP_MANAGER_IX created.

Index EMP_NAME_IX created.

Index DEPT_LOCATION_IX created.

Index JHIST_JOB_IX created.

Index JHIST_EMPLOYEE_IX created.

Index JHIST_DEPARTMENT_IX created.

Index LOC_CITY_IX created.

Index LOC_STATE_PROVINCE_IX created.

Index LOC_COUNTRY_IX created.

Commit complete.

Procedure SECURE_DML compiled

Trigger SECURE_EMPLOYEES compiled

Trigger SECURE_EMPLOYEES altered.

Procedure ADD_JOB_HISTORY compiled

Trigger UPDATE_JOB_HISTORY compiled

Commit complete.

Comment created.
[...]
Commit complete.

PL/SQL procedure successfully completed.

SQL>
```

## Base Tables and Editioning Views
The set of scripts that install the `HR` schema is different from the default one.
The file `hr_main.sql` gives extra grants to the `HR` user:
```
GRANT CREATE ANY EDITION TO hr;
ALTER USER hr ENABLE EDITIONS;
```

Also give a look at the file `hr_cre.sql`. Each table has a different name compared to the original `HR` schema (a suffix `$0` in this example):
```
CREATE TABLE regions$0
    ( region_id      NUMBER
       CONSTRAINT  region_id_nn NOT NULL
    , region_name    VARCHAR2(25)
    );
```
Each table has a corresponding *editioning view* that covers the table 1 to 1:
```
CREATE EDITIONING VIEW regions as
    SELECT region_id, region_name FROM regions$0;
```

The views, and all the depending objects, are editioned and belong to the `ORA$BASE` edition.
```
SQL> select OBJECT_NAME, OBJECT_TYPE, EDITION_NAME from user_objects_ae WHERE edition_name is not null  order by 2,3;

          OBJECT_NAME    OBJECT_TYPE    EDITION_NAME
_____________________ ______________ _______________
ADD_JOB_HISTORY       PROCEDURE      ORA$BASE
SECURE_DML            PROCEDURE      ORA$BASE
SECURE_EMPLOYEES      TRIGGER        ORA$BASE
UPDATE_JOB_HISTORY    TRIGGER        ORA$BASE
JOBS                  VIEW           ORA$BASE
JOB_HISTORY           VIEW           ORA$BASE
EMP_DETAILS_VIEW      VIEW           ORA$BASE
DEPARTMENTS           VIEW           ORA$BASE
LOCATIONS             VIEW           ORA$BASE
COUNTRIES             VIEW           ORA$BASE
REGIONS               VIEW           ORA$BASE
EMPLOYEES             VIEW           ORA$BASE

12 rows selected.
```

## Generate the base changelog for liquibase
The command `lb genschema` creates the base Liquibase changelog. Run it from `../changes/hr.00000.base` directory:
```
SQL> show user
USER is "HR"
SQL> cd ../changes/hr.00000.base
SQL> lb genschema


Export Flags Used:

Export Grants           false
Export Synonyms         false
[Method loadCaptureTable]:
                 Executing
[Type - TYPE_SPEC]:                          379 ms
[Type - TYPE_BODY]:                          179 ms
[Type - SEQUENCE]:                           136 ms
[Type - DIRECTORY]:                           55 ms
[Type - CLUSTER]:                           1050 ms
[Type - TABLE]:                            11620 ms
[Type - MATERIALIZED_VIEW_LOG]:               63 ms
[Type - MATERIALIZED_VIEW]:                   52 ms
[Type - VIEW]:                              2366 ms
[Type - REF_CONSTRAINT]:                     348 ms
[Type - DIMENSION]:                           52 ms
[Type - FUNCTION]:                            91 ms
[Type - PROCEDURE]:                          117 ms
[Type - PACKAGE_SPEC]:                        87 ms
[Type - DB_LINK]:                             52 ms
[Type - SYNONYM]:                             73 ms
[Type - INDEX]:                             1153 ms
[Type - TRIGGER]:                            158 ms
[Type - PACKAGE_BODY]:                       114 ms
[Type - JOB]:                                 63 ms
                 End
[Method loadCaptureTable]:                 18208 ms
[Method processCaptureTable]:              13787 ms
[Method sortCaptureTable]:                    54 ms
[Method cleanupCaptureTable]:                 24 ms
[Method writeChangeLogs]:                   6928 ms
```

The base changelog is only useful if you plan to recreate the schema from scratch by using `Liquibase` instead of the base scripts.
Notice that the `HR` schema creation is not included in the changelog.

The Liquibase changelog is created as a set of xml files:
```
SQL> exit
$ cd ../changes/hr.00000.base
$ ls -l
total 114
-rw-r--r--    1 LCALDARA UsersGrp      1214 Mar 14 15:50 add_job_history_procedure.xml
-rw-r--r--    1 LCALDARA UsersGrp      2717 Mar 14 15:50 controller.xml
-rw-r--r--    1 LCALDARA UsersGrp       823 Mar 14 15:50 countr_reg_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1080 Mar 14 15:50 countries$0_comments.xml
-rw-r--r--    1 LCALDARA UsersGrp      3884 Mar 14 15:50 countries$0_table.xml
-rw-r--r--    1 LCALDARA UsersGrp      1208 Mar 14 15:50 countries_view.xml
-rw-r--r--    1 LCALDARA UsersGrp      1588 Mar 14 15:50 departments$0_comments.xml
-rw-r--r--    1 LCALDARA UsersGrp      4134 Mar 14 15:50 departments$0_table.xml
-rw-r--r--    1 LCALDARA UsersGrp       950 Mar 14 15:50 departments_seq_sequence.xml
-rw-r--r--    1 LCALDARA UsersGrp      1320 Mar 14 15:50 departments_view.xml
-rw-r--r--    1 LCALDARA UsersGrp       827 Mar 14 15:50 dept_loc_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1731 Mar 14 15:50 dept_location_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp       826 Mar 14 15:50 dept_mgr_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1733 Mar 14 15:50 emp_department_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp       831 Mar 14 15:50 emp_dept_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      2749 Mar 14 15:50 emp_details_view_view.xml
-rw-r--r--    1 LCALDARA UsersGrp      1736 Mar 14 15:50 emp_email_uk_index.xml
-rw-r--r--    1 LCALDARA UsersGrp       808 Mar 14 15:50 emp_job_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1712 Mar 14 15:50 emp_job_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp       830 Mar 14 15:50 emp_manager_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1724 Mar 14 15:50 emp_manager_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp      1804 Mar 14 15:50 emp_name_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp      2296 Mar 14 15:50 employees$0_comments.xml
-rw-r--r--    1 LCALDARA UsersGrp      7249 Mar 14 15:50 employees$0_table.xml
-rw-r--r--    1 LCALDARA UsersGrp       969 Mar 14 15:50 employees_seq_sequence.xml
-rw-r--r--    1 LCALDARA UsersGrp      1916 Mar 14 15:50 employees_view.xml
-rw-r--r--    1 LCALDARA UsersGrp      1739 Mar 14 15:50 jhist_department_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp       837 Mar 14 15:50 jhist_dept_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp       829 Mar 14 15:50 jhist_emp_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1733 Mar 14 15:50 jhist_employee_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp       814 Mar 14 15:50 jhist_job_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1718 Mar 14 15:50 jhist_job_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp      2058 Mar 14 15:50 job_history$0_comments.xml
-rw-r--r--    1 LCALDARA UsersGrp      4817 Mar 14 15:50 job_history$0_table.xml
-rw-r--r--    1 LCALDARA UsersGrp      1388 Mar 14 15:50 job_history_view.xml
-rw-r--r--    1 LCALDARA UsersGrp      1171 Mar 14 15:50 jobs$0_comments.xml
-rw-r--r--    1 LCALDARA UsersGrp      4122 Mar 14 15:50 jobs$0_table.xml
-rw-r--r--    1 LCALDARA UsersGrp      1271 Mar 14 15:50 jobs_view.xml
-rw-r--r--    1 LCALDARA UsersGrp       823 Mar 14 15:50 loc_c_id_fk_ref_constraint.xml
-rw-r--r--    1 LCALDARA UsersGrp      1712 Mar 14 15:50 loc_city_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp      1724 Mar 14 15:50 loc_country_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp      1742 Mar 14 15:50 loc_state_province_ix_index.xml
-rw-r--r--    1 LCALDARA UsersGrp      1861 Mar 14 15:50 locations$0_comments.xml
-rw-r--r--    1 LCALDARA UsersGrp      4598 Mar 14 15:50 locations$0_table.xml
-rw-r--r--    1 LCALDARA UsersGrp       948 Mar 14 15:50 locations_seq_sequence.xml
-rw-r--r--    1 LCALDARA UsersGrp      1484 Mar 14 15:50 locations_view.xml
-rw-r--r--    1 LCALDARA UsersGrp      1028 Mar 14 15:50 regions$0_comments.xml
-rw-r--r--    1 LCALDARA UsersGrp      3660 Mar 14 15:50 regions$0_table.xml
-rw-r--r--    1 LCALDARA UsersGrp      1110 Mar 14 15:50 regions_view.xml
-rw-r--r--    1 LCALDARA UsersGrp       980 Mar 14 15:50 secure_dml_procedure.xml
-rw-r--r--    1 LCALDARA UsersGrp       870 Mar 14 15:50 secure_employees_trigger.xml
-rw-r--r--    1 LCALDARA UsersGrp       977 Mar 14 15:50 update_job_history_trigger.xml
```

The `controller.xml` is the changelog file that contains the changesets. You can see that the changesets are called from the current path:
```
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
  xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                      http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.9.xsd">
  <include file="employees_seq_sequence.xml" relativeToChangelogFile="true" />
  <include file="locations_seq_sequence.xml" relativeToChangelogFile="true" />
  <include file="departments_seq_sequence.xml" relativeToChangelogFile="true" />
  [...]
  <include file="update_job_history_trigger.xml" relativeToChangelogFile="true" />
  <include file="secure_employees_trigger.xml" relativeToChangelogFile="true" />
</databaseChangeLog>
```

In real life, development should happen either on an anonymized copy of the production, or on the same data structures but with a development data set. There are ways to achieve this result that we will not discuss here.

## Create your own directory structure
For this and subsequent changelogs, you might want to use a neater directory organization, for example:
```
main.xml
  -> sub_changelog_1.xml
    -> sub_changelog_1/changesets*
  -> sub_changelog_2.xml
    -> sub_changelog_2/changesets*
```
Having each changelog contained in a separate directory facilitates the development when schemas start getting bigger and the number of changesets important.

For this reason, you can convert the file `hr.00000.base/controller.xml` to `hr.00000.base.xml`. This part is subjective. Different development teams may prefer different directory layouts.

The conversion can be achieved with:
```
sed -e "s/file=\"/file=\"hr.00000.base\//" hr.00000.base/controller.xml > hr.00000.base.xml
```
so that the `<include>` in the new file look like (notice the new path):
```
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
  xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                      http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.9.xsd">
  <include file="hr.00000.base/employees_seq_sequence.xml" relativeToChangelogFile="true" />
  <include file="hr.00000.base/locations_seq_sequence.xml" relativeToChangelogFile="true" />
  <include file="hr.00000.base/departments_seq_sequence.xml" relativeToChangelogFile="true" />
  <include file="hr.00000.base/departments$0_table.xml" relativeToChangelogFile="true" />
  [...]
  <include file="hr.00000.base/update_job_history_trigger.xml" relativeToChangelogFile="true" />
  <include file="hr.00000.base/secure_employees_trigger.xml" relativeToChangelogFile="true" />
</databaseChangeLog>
```

The file `main.xml` will be something like:
```
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
  xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                      http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd">

  <include file="./hr.00000.base.xml" relativeToChangelogFile="true"/>
  <!-- PLACEHOLDER <include file="./hr.00001.edition_v1.xml" relativeToChangelogFile="true"/>  -->
  <!-- PLACEHOLDER <include file="./hr.00002.edition_v2.xml" relativeToChangelogFile="true"/>  -->

</databaseChangeLog>
```

Note that there are already two placeholders for the next schema/code releases.

At this point, the command `lb genschema` has generated the initial changelog, but the current schema is not synchronized with Liquibase yet.
```
SQL> cd ..
SQL> lb status -changelog main.xml

51 change sets have not been applied to HR@jdbc:oracle:thin:@(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.eu-zurich-1.oraclecloud.com))(connect_data=(service_name=ht8k3jwmatw52we_demoadb_medium.adb.oraclecloud.com))(security=(ssl_server_cert_dn="CN=adb.eu-zurich-1.oraclecloud.com, OU=Oracle ADB ZURICH, O=Oracle Corporation, L=Redwood City, ST=California, C=US")))
     hr.00000.base/employees_seq_sequence.xml::42e3db1348e500dade36829bab3b7f5343ad6f09::(HR)-Generated
     hr.00000.base/locations_seq_sequence.xml::7ec49fad51eb8c0b53fa0128bf6ef2d3fee25d35::(HR)-Generated
     hr.00000.base/departments_seq_sequence.xml::93020a4f5c3fc570029b0695d52763142b6e44e1::(HR)-Generated
     hr.00000.base/departments$0_table.xml::8fccd55150e9ae05304edde806cb429fdc3b875f::(HR)-Generated
[...]

```
We can synch it with an `lb update`.
```
SQL> lb update -changelog main.xml

ScriptRunner Executing: hr.00000.base/employees_seq_sequence.xml::42e3db1348e500dade36829bab3b7f5343ad6f09::(HR)-Generated
 -- DONE
ScriptRunner Executing: hr.00000.base/locations_seq_sequence.xml::7ec49fad51eb8c0b53fa0128bf6ef2d3fee25d35::(HR)-Generated
 -- DONE
ScriptRunner Executing: hr.00000.base/departments_seq_sequence.xml::93020a4f5c3fc570029b0695d52763142b6e44e1::(HR)-Generated
 -- DONE
ScriptRunner Executing: hr.00000.base/departments$0_table.xml::8fccd55150e9ae05304edde806cb429fdc3b875f::(HR)-Generated
[...]
```

The next `lb status` shows everything up to date. A subsequent `lb update` will not change anything.
```
SQL> lb status -changelog main.xml

HR@jdbc:oracle:thin:@(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.eu-zurich-1.oraclecloud.com))(connect_data=(service_name=ht8k3jwmatw52we_demoadb_medium.adb.oraclecloud.com))(security=(ssl_server_cert_dn="CN=adb.eu-zurich-1.oraclecloud.com, OU=Oracle ADB ZURICH, O=Oracle Corporation, L=Redwood City, ST=California, C=US"))) is up to date

SQL> lb update -changelog main.xml

######## ERROR SUMMARY ##################
Errors encountered:0

######## END ERROR SUMMARY ##################
```


## Create a new edition to add the `dn` column to `departments` and `employees`
As an example of schema change, let's start with a basic `add column`. We'll use the same modifications as the file [`hr_dn_c.sql`](https://github.com/oracle/db-sample-schemas/tree/main/human_resources) in the official `db-sample-schemas` repository.

To achieve this goal with `EBR` and Liquibase, I have splitted the file in multiple SQL files:
```
hr.000001.edition_v1.sql
hr.000002.alter_session.sql
hr.000003.alter_departments_add_dn.sql
hr.000004.view_departments.sql
hr.000005.alter_employees_add_dn.sql
hr.000006.view_employees.sql
hr.000007.update_dn.sql
hr.000008.procedure_secure_dml.sql
hr.000009.trigger_secure_employees.sql
hr.000010.procedure_add_job_history.sql
hr.000011.trigger_update_job_history.sql
```

The first two are the important ones for `EBR`.
The first one creates the edition, but as the edition is a database-wide configuration, if there are other schemas using the same versions, we don't want to have any error `ORA-00955` because of any existing editions, so the code just skips that error:
```
-- hr.000001.edition_v1.sql
declare
  e_edition_exists exception;
  pragma exception_init (e_edition_exists, -955);
begin
  begin
    execute immediate 'CREATE EDITION v1';
  exception
    when e_edition_exists then null;
  end;
end;
/
```

The second one is also important, as it sets the edition for the subsequent changesets:
```
-- hr.000002.alter_session.sql
ALTER SESSION SET EDITION=v1;
```

This changeset must always be run in the changelog before other changelogs are executed (in case liquibase disconnects and reconnects again due to errors), so we will call it with the parameter `runAlways=true`:

```
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
  xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                      http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd">

    <changeSet author="lcaldara" id="hr.000001.edition_v1">
      <sqlFile dbms="oracle" endDelimiter=";"
               path="hr.00001.edition_v1/hr.000001.edition_v1.sql"
               relativeToChangelogFile="true" splitStatements="false" stripComments="false"/>
    </changeSet>
    <changeSet author="lcaldara" id="hr.000002.alter_session" runAlways="true">
      <sqlFile dbms="oracle" endDelimiter=";"
               path="hr.00001.edition_v1/hr.000002.alter_session.sql"
               relativeToChangelogFile="true" splitStatements="true" stripComments="false"/>
    </changeSet>
    [...]
</databaseChangeLog>
```
The other changesets have a different `splitStatements` parameter depending on their nature (SQL or PL/SQL).

The next `lb update` statement will propagate also these changes... continue here