-- moviestream.000011.customer_reverse_trigger.sql
create or replace trigger customer_revxedition_trg
  before insert or update of country_code on customer$0
  for each row
  reverse crossedition
  disable
declare
  country   customer$0.country%type;
  continent customer$0.continent%type;
begin
  if :new.country is null or :new.continent is null
  then
    select nvl(substr(country,1,instr(country,',')-1),country),
        continents$0.continent 
      into :new.country, :new.continent
    from countries$0, continents$0
      where countries$0.continent_code = continents$0.continent_code
        and countries$0.country_code = :new.country_code;
  end if;
end;
/
