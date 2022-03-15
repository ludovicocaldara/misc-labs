ALTER TABLE employees$0
 ADD dn VARCHAR2(300);

COMMENT ON COLUMN employees$0.dn IS
'Distinguished name of the employee.
e.g. "cn=Lisa Ozer, ou=Sales, o=IMC, c=us"';
