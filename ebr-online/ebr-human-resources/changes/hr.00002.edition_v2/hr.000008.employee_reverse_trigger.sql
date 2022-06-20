-- hr.000008.employee_reverse_trigger.sql
create or replace trigger employees_revxedition_trg
  before insert or update of country_code,phone# on employees$0
  for each row
  reverse crossedition
  disable
declare
    first_dot  number;
    second_dot number;
begin
        if :new.country_code = '+1'
        then
           :new.phone_number :=
              :new.phone#;
        else
           :new.phone_number :=
              '011.' ||
              substr( :new.country_code, 2 ) ||
              '.' || :new.phone#;
        end if;
end;
/
