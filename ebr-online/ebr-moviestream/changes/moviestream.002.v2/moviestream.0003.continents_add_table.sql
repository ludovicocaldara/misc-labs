-- moviestream.000003.continents_add_table.sql
create table continents$0 (
    continent_code varchar2(2) not null
   ,continent varchar2(400) not null
   ,constraint pk_continents primary key  (continent_code)
   );
