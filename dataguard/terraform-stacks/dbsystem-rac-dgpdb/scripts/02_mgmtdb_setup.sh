GI_HOME=$(cat /etc/oracle/olr.loc 2>/dev/null | grep crs_home | awk -F= '{print $2}')

export ORACLE_HOME=$GI_HOME

$ORACLE_HOME/bin/mgmtca createGIMRContainer -storageDiskLocation +DATA


export ORACLE_SID=-MGMTDB

$ORACLE_HOME/bin/sqlplus / as sysdba <<EOF
alter system set local_listener='$HOSTNAME:1526';
alter system register;
EOF

$ORACLE_HOME/bin/mgmtca -local

$ORACLE_HOME/bin/sqlplus / as sysdba <<EOF
alter session set container=GIMR_DSCREP_10;
alter user ghsuser19 account unlock;
EOF
