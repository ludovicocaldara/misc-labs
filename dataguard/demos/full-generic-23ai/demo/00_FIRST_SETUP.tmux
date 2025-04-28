---# Instruction: the lab uses a unique resId (23 here). Change it to match what you deployed
--- tmux split-window
---# ---------------------------------------  CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
ssh opc@adghol0-23.adghol23.misclabs.oraclevcn.com
--- sleep 1
---# ------------------------------------- INSTALL RPM PACKAGES
sudo dnf install -y git
---# ------------------------------------- PREPARE SQLcl SHORTCUT
sudo su - oracle
---# ------------------------------------- DOWNLOAD THE HELPER FILES
git clone -b main -n --filter=tree:0 --depth=1 https://github.com/oracle-livelabs/database-maa.git
cd database-maa
git sparse-checkout set --no-cone data-guard/active-data-guard-23ai/prepare-host/scripts
git checkout
cd
sh ~/database-maa/data-guard/active-data-guard-23ai/prepare-host/scripts/prepare.sh
cat $ORACLE_HOME/network/admin/listener.ora
cat $ORACLE_HOME/network/admin/tnsnames.ora
---# ---------------------------------------- CONNECTION TO THE SECOND HOST
--- tmux select-pane -t :.1
ssh opc@adghol1-23.adghol23.misclabs.oraclevcn.com
--- sleep 1
---# ------------------------------------- INSTALL RPM PACKAGES
sudo dnf install -y git
---# ------------------------------------- PREPARE SQLcl SHORTCUT
sudo su - oracle
---# ------------------------------------- DOWNLOAD THE HELPER FILES
git clone -b main -n --filter=tree:0 --depth=1 https://github.com/oracle-livelabs/database-maa.git
cd database-maa
git sparse-checkout set --no-cone data-guard/active-data-guard-23ai/prepare-host/scripts
git checkout
cd
sh ~/database-maa/data-guard/active-data-guard-23ai/prepare-host/scripts/prepare.sh
cat $ORACLE_HOME/network/admin/listener.ora
cat $ORACLE_HOME/network/admin/tnsnames.ora
tnsping adghol_site0
tnsping adghol_site0_dgmgrl
tnsping adghol_site1
tnsping adghol_site1_dgmgrl
---# ----------------------------------------  COPY THE TDE WALLET
--- tmux select-pane -t :.0
cd /opt/oracle/dcs/commonstore/wallets/$ORACLE_UNQNAME/tde
tar cvf /tmp/wallet.tar cwallet.sso ewallet.p12
cp $ORACLE_HOME/dbs/orapwadghol /tmp
chmod 644 /tmp/orapwadghol
exit
exit
scp adghol0-23.adghol23.misclabs.oraclevcn.com:/tmp/wallet.tar /tmp
scp adghol0-23.adghol23.misclabs.oraclevcn.com:/tmp/orapwadghol /tmp
scp /tmp/wallet.tar adghol1-23.adghol23.misclabs.oraclevcn.com:/tmp
scp /tmp/orapwadghol adghol1-23.adghol23.misclabs.oraclevcn.com:/tmp
rm /tmp/wallet.tar
rm /tmp/orapwadghol
ssh opc@adghol0-23.adghol23.misclabs.oraclevcn.com
sudo su - oracle
rm /tmp/wallet.tar
rm /tmp/orapwadghol
--- tmux select-pane -t :.1
cd /opt/oracle/dcs/commonstore/wallets/$ORACLE_UNQNAME/tde
tar xvf /tmp/wallet.tar
cp /tmp/orapwadghol $ORACLE_HOME/dbs
chmod 600 $ORACLE_HOME/dbs/orapwadghol
exit
rm /tmp/wallet.tar
rm /tmp/orapwadghol
sudo su - oracle
sqlplus / as sysdba
startup nomount force
exit
