-- moviestream.000004.countries_add_table.sql
create table countries$0 (
    country_code varchar2(2) not null
   ,country varchar2(400) not null
   ,continent_code varchar2(2) not null
   ,constraint pk_countries primary key  (country_code)
   ,constraint fk_country_continent foreign key (continent_code)
      references continents$0 (continent_code)
   );
