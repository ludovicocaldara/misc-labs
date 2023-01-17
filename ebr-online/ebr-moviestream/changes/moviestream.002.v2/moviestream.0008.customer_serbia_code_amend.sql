-- moviestream.000008.customer_serbia_code_amend.sql
-- official code for Serbia since 2006
update customer set country_code='RS' where country_code='CS';
