set define off
exec x.kill_all_sessions_for_user('ebr_user');
exec x.kill_sessions_using_other_edns();
exec x.drop_user('ebr_user');
exec x.drop_all_editions_enabld_usrs;
exec x.drop_all_edns_but_curr_root();


grant dba to ebr_user identified by ebr_user;
alter user ebr_user enable editions;
/*
create edition e1;
create edition e2;
grant use on edition e1 to ebr_user;
grant use on edition e2 to ebr_user;
*/