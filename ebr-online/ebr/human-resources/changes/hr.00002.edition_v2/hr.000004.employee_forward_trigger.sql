create or replace trigger employees_fwdxedition_trg
  before insert or update of phone_number on employees$0
  for each row
  forward crossedition
  disable
declare
    first_dot  number;
    second_dot number;
begin
    if :new.phone_number like '011.%'
   then
        first_dot
           := instr( :new.phone_number, '.' );
        second_dot
           := instr( :new.phone_number, '.', 1, 2 );
        :new.country_code
           := '+'||
              substr( :new.phone_number,
                        first_dot+1,
                      second_dot-first_dot-1 );
        :new.phone#
           := substr( :new.phone_number,
                        second_dot+1 );
    else
        :new.country_code := '+1';
        :new.phone# := :new.phone_number;
    end if;
end;
/
