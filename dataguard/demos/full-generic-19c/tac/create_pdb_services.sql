DECLARE
    e_service_error EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_service_error  , -44786);
    params dbms_service.svc_parameter_array;
    service_name v$services.name%TYPE;
BEGIN
    -- parameters for TAC
    params('FAILOVER_TYPE')            :='AUTO';
    params('FAILOVER_RESTORE')         :='AUTO';
    params('FAILOVER_DELAY')           :=2;
    params('FAILOVER_RETRIES')         :=150;
    params('commit_outcome')           :='true';
    params('aq_ha_notifications')      :='true';
    params('REPLAY_INITIATION_TIMEOUT'):=1800;
    params('RETENTION_TIMEOUT')        :=86400;
    params('DRAIN_TIMEOUT')            :=30;

    service_name := rtrim(sys_context('userenv', 'db_name')||'_RW.'|| sys_context('userenv','db_domain'), '.');
    BEGIN
        DBMS_SERVICE.CREATE_SERVICE ( service_name => service_name, network_name => service_name);
    EXCEPTION
        WHEN DBMS_SERVICE.SERVICE_EXISTS THEN  null;
    END;
    DBMS_SERVICE.MODIFY_SERVICE(service_name, params);

    service_name := rtrim(sys_context('userenv', 'db_name')||'_SNAP.'|| sys_context('userenv','db_domain'), '.');
    BEGIN
        DBMS_SERVICE.CREATE_SERVICE ( service_name => service_name, network_name => service_name);
    EXCEPTION
        WHEN DBMS_SERVICE.SERVICE_EXISTS THEN  null;
    END;
    DBMS_SERVICE.MODIFY_SERVICE(service_name, params);

    service_name := rtrim(sys_context('userenv', 'db_name')||'_RO.'|| sys_context('userenv','db_domain'), '.');
    BEGIN
        DBMS_SERVICE.CREATE_SERVICE ( service_name => service_name, network_name => service_name);
    EXCEPTION
        WHEN DBMS_SERVICE.SERVICE_EXISTS THEN  null;
    END;
    DBMS_SERVICE.MODIFY_SERVICE(service_name, params);
END;
/
