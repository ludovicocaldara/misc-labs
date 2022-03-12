SET LINESIZE 60

PROMPT Base table t_
DESCRIBE t_

PROMPT Editioning view t
DESCRIBE t

SET LINESIZE 32727

COLUMN Index_Name FORMAT A20
select Index_Name from Sys.User_Indexes order by 1
/

COLUMN Constraint_Name FORMAT A20
COLUMN Constraint_Type FORMAT A15
COLUMN Table_Name FORMAT A10
COLUMN Column_Name FORMAT A11

select Constraint_Name, cc.Column_Name, c.Constraint_Type
from Sys.User_Constraints c inner join Sys.User_Cons_Columns cc
using (Constraint_Name, Table_Name)
where Table_Name = 'T_'
and Constraint_Name not like 'SYS%'
order by 1, 2
/
