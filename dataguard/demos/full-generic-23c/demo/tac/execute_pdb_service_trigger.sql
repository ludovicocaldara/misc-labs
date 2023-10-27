DECLARE
  v_service_ro    VARCHAR2(64) := rtrim(sys_context('userenv', 'db_name') || '_RO.' || sys_context('userenv', 'db_domain'), '.');
  v_service_rw    VARCHAR2(64) := rtrim(sys_context('userenv', 'db_name') || '_RW.' || sys_context('userenv', 'db_domain'), '.');
  v_service_snap  VARCHAR2(64) := rtrim(sys_context('userenv', 'db_name') || '_SNAP.' || sys_context('userenv', 'db_domain'), '.');
  v_ro_service_count   NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO v_ro_service_count
  FROM
    v
  WHERE
    name = v_service_ro;
  IF sys_context('userenv', 'database_role') IN (
    'PRIMARY',
    'SNAPSHOT STANDBY'
    ) AND v_ro_service_count = 1 THEN
      dbms_service.stop_service(v_service_ro);
      dbms_service.disconnect_session(v_service_ro, dbms_service.immediate);
  END IF;
  IF sys_context('userenv', 'database_role') = 'PRIMARY' THEN
    dbms_service.start_service(v_service_rw);
  ELSIF sys_context('userenv', 'database_role') = 'SNAPSHOT STANDBY' THEN
    dbms_service.start_service(v_service_snap);
  ELSIF v_ro_service_count = 0 THEN
      dbms_service.start_service(v_service_ro);
    END IF;
END;
/
