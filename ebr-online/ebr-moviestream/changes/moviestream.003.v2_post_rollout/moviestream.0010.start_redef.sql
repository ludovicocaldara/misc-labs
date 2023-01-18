-- moviestream.000010.start_redef.sql
declare
  l_colmap varchar(1024);
begin
  l_colmap := 'CUST_ID , LAST_NAME , FIRST_NAME , EMAIL ,
 STREET_ADDRESS , POSTAL_CODE , CITY , STATE_PROVINCE ,
 COUNTRY_CODE , YRS_CUSTOMER , PROMOTION_RESPONSE ,
 LOC_LAT , LOC_LONG , AGE , COMMUTE_DISTANCE ,
 CREDIT_BALANCE , EDUCATION , FULL_TIME , GENDER ,
 HOUSEHOLD_SIZE , INCOME , INCOME_LEVEL ,
 INSUFF_FUNDS_INCIDENTS , JOB_TYPE , LATE_MORT_RENT_PMTS ,
 MARITAL_STATUS , MORTGAGE_AMT , NUM_CARS , NUM_MORTGAGES ,
 PET , RENT_OWN , SEGMENT_ID , WORK_EXPERIENCE ,
 YRS_CURRENT_EMPLOYER , YRS_RESIDENCE';
	
  dbms_redefinition.start_redef_table (
    uname        => user,
    orig_table   => 'CUSTOMER$0',
    int_table    => 'CUSTOMER$INTERIM', 
    col_mapping  => l_colmap
  );
end;
/
