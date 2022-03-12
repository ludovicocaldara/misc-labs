select Edition_Name, Object_Name, Status
from User_Objects_AE
where Edition_Name is not null
and Object_Type <> 'NON-EXISTENT'
order by 1, 2
/
