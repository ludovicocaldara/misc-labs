declare
  l_colmap varchar(512);
begin
  l_colmap :=
    'employee_id
    , first_name    
    , last_name     
    , email         
    , country_code  
    , phone#        
    , hire_date     
    , job_id        
    , salary        
    , commission_pct
    , manager_id    
    , department_id';
	
  dbms_redefinition.start_redef_table (
    uname        => user,
    orig_table   => 'EMPLOYEES$0',
    int_table    => 'EMPLOYEES$INTERIM', 
    col_mapping  => l_colmap
  );
end;
/
