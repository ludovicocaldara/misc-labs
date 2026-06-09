useradd demo
sudo -u demo wget https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip -O ~demo/sqlcl-latest.zip
sudo -u demo unzip ~demo/sqlcl-latest.zip

cat <<EOF > /etc/yum.repos.d/oracle-instantclient-ol8.repo
[ol8_oracle_instantclient]
name=Oracle InstantClient for OCI users on Oracle Linux $releasever (\$basearch)
baseurl=https://yum\$ociregion.\$ocidomain/repo/OracleLinux/OL8/oracle/instantclient/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF

dnf install -y jdk-17

sudo -u demo bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh --accept-all-defaults)"

sudo -u demo base64 -d /tmp/adb_wallet.zip.base64 > ~demo/adb_wallet.zip
