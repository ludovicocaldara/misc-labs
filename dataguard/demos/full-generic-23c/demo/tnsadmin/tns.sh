L_pdb="phol23c"
L_types="rw ro snap"
L_hosts="hol23c0.dbhol23c.misclabs.oraclevcn.com hol23c1.dbhol23c.misclabs.oraclevcn.com"
L_domain="dbhol23c.misclabs.oraclevcn.com"

for L_type in ${L_types} ; do
cat <<EOF

${L_pdb}_${L_type}.${L_domain} =
  (DESCRIPTION =
    (CONNECT_TIMEOUT=240)(RETRY_COUNT=150)(RETRY_DELAY=2)
    (TRANSPORT_CONNECT_TIMEOUT=3)
EOF

for L_host in $L_hosts ; do
cat <<EOF
    (ADDRESS_LIST =
      (LOAD_BALANCE=on)
      (ADDRESS=(PROTOCOL=TCP)(HOST=${L_host}.${L_domain})(PORT=1521)))
EOF
done
cat <<EOF
    (CONNECT_DATA=(SERVICE_NAME = ${L_pdb}_${L_type}.${L_domain})))
EOF


done

