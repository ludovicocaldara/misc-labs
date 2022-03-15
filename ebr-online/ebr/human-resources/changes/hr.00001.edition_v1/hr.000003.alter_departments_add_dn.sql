ALTER TABLE departments$0
 ADD dn VARCHAR2(300);

COMMENT ON COLUMN departments$0.dn IS
'Distinguished name for each deparment.
e.g: "ou=Purchasing, o=IMC, c=US"';
