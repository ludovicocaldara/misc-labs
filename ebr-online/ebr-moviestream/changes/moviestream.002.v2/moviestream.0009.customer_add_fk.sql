-- moviestream.000009.customer_add_fk.sql
create index customer_country_code_idx on customer$0 (country_code);

alter table customer$0 add constraint fk_customer_countries
  foreign key (country_code) references countries$0 (country_code);
