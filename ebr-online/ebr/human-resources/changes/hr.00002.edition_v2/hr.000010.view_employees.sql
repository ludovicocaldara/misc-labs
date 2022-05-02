-- hr.000010.view_employees.sql
CREATE OR REPLACE EDITIONING VIEW employees AS
    SELECT employee_id, first_name, last_name, email, country_code, phone#, hire_date, job_id, salary, commission_pct, manager_id, department_id FROM employees$0;
