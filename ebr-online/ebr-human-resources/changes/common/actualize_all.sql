declare
     type obj_t is record(
         object_name user_objects.object_name%type,
         namespace   user_objects.namespace%type);
     type obj_tt is table of obj_t;

     l_obj_list obj_tt;

     l_obj_count binary_integer := 0;

 begin
     dbms_editions_utilities2.actualize_all;
     loop
         select object_name,namespace
         bulk   collect
         into   l_obj_list
         from   user_objects
         where  edition_name != sys_context('userenv', 'session_edition_name')
         or     status = 'INVALID';

         exit when l_obj_list.count = l_obj_count;

         l_obj_count := l_obj_list.count;

         for i in 1 .. l_obj_count
         loop
             dbms_utility.validate(user, l_obj_list(i).object_name, l_obj_list(i).namespace);
         end loop;
     end loop;
 end;
 /
