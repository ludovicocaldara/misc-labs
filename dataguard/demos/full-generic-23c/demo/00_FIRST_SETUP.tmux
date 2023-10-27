--- tmux setenv remote_host 140.238.100.79
--- export remote_host=140.238.100.79
--- ## testing ping to server...
--- ping -w 5000 -n 1 ${remote_host} || exit
--- tmux display-message "server ok."
--- tmux split-window
---# ---------------------------------------  CONNECTION TO THE FIRST HOST
--- tmux select-pane -t :.0
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
ssh opc@hol23c0.dbhol23c
--- sleep 1
---# ------------------------------------- INSTALL RPM PACKAGES
sudo su -
dnf install -y java-17-openjdk git
exit
---# ------------------------------------- PREPARE SQLcl SHORTCUT
sudo su - oracle
wget https://gist.githubusercontent.com/ludovicocaldara/45252073ccb6c2b9de6741dde90a582a/raw/49180ee9cd083593291a7bf1d4a25acf82e8e374/sqlcl.sh
cat <<EOF >> ~/.bash_profile
export JAVA_HOME=/usr/lib/jvm/jre-17
export PATH=\$JAVA_HOME/bin:\$PATH
. ~/sqlcl.sh
EOF
. ~/.bash_profile
---# ------------------------------------- DOWNLOAD THE HELPER FILES
git clone -n --filter=tree:0 --depth=1 https://github.com/ludovicocaldara/misc-labs.git
cd misc-labs
git sparse-checkout set --no-cone dataguard/demos/full-generic-23c/demo
git checkout
cd
clear
echo $ORACLE_UNQNAME
---# ------------------------------------- SET THE STATIC LISTENER ENTRY
grep SID_LIST_LISTENER $ORACLE_HOME/network/admin/listener.ora || cat <<EOF >> $ORACLE_HOME/network/admin/listener.ora
# add static listener registration for Data Guard and duplicate
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = cdgsima)
      (GLOBAL_DBNAME=${ORACLE_UNQNAME}_DGMGRL.dbhol23c.misclabs.oraclevcn.com)
      (ORACLE_HOME = $ORACLE_HOME)
    )
  )
EOF
cat $ORACLE_HOME/network/admin/listener.ora
lsnrctl reload
---# ------------------------------------- POPULATE TNSNAMES
cat $ORACLE_HOME/network/admin/tnsnames.ora
grep _rw $ORACLE_HOME/network/admin/tnsnames.ora || sh  /home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/tnsadmin/tns.sh >> $ORACLE_HOME/network/admin/tnsnames.ora
cat $ORACLE_HOME/network/admin/tnsnames.ora
---# ---------------------------------------- CONNECTION TO THE SECOND HOST
--- tmux select-pane -t :.1
eval "export $(tmux show-environment remote_host)"
echo remote_host=$remote_host 
--- tmux send-keys 'ssh opc@${remote_host}' C-M
--- sleep 1
echo -e '$if Gdb\n"\\e[6~": "\\n"\n$endif' > ~/.inputrc
ssh opc@hol23c1.dbhol23c
--- sleep 1
---# ------------------------------------- INSTALL RPM PACKAGES
sudo su -
dnf install -y java-17-openjdk git
exit
---# ------------------------------------- PREPARE SQLcl SHORTCUT
sudo su - oracle
wget https://gist.githubusercontent.com/ludovicocaldara/45252073ccb6c2b9de6741dde90a582a/raw/49180ee9cd083593291a7bf1d4a25acf82e8e374/sqlcl.sh
cat <<EOF >> ~/.bash_profile
export JAVA_HOME=/usr/lib/jvm/jre-17
export PATH=\$JAVA_HOME/bin:\$PATH
. ~/sqlcl.sh
EOF
. ~/.bash_profile
---# ------------------------------------- DOWNLOAD THE HELPER FILES
git clone -n --filter=tree:0 --depth=1 https://github.com/ludovicocaldara/misc-labs.git
cd misc-labs
git sparse-checkout set --no-cone dataguard/demos/full-generic-23c/demo
git checkout
cd
clear
ps -eaf | grep pmon
echo $ORACLE_UNQNAME
---# ------------------------------------- SET THE STATIC LISTENER ENTRY
grep SID_LIST_LISTENER $ORACLE_HOME/network/admin/listener.ora || cat <<EOF >> $ORACLE_HOME/network/admin/listener.ora
# add static listener registration for Data Guard and duplicate
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = chol23c)
      (GLOBAL_DBNAME=${ORACLE_UNQNAME}_DGMGRL.dbhol23c.misclabs.oraclevcn.com)
      (ORACLE_HOME = $ORACLE_HOME)
    )
  )
EOF
cat $ORACLE_HOME/network/admin/listener.ora
lsnrctl reload
---# ------------------------------------- POPULATE TNSNAMES
cat $ORACLE_HOME/network/admin/tnsnames.ora
grep _rw $ORACLE_HOME/network/admin/tnsnames.ora || sh  /home/oracle/misc-labs/dataguard/demos/full-generic-23c/demo/tnsadmin/tns.sh >> $ORACLE_HOME/network/admin/tnsnames.ora
cat $ORACLE_HOME/network/admin/tnsnames.ora

---# ----------------------------------------  COPY THE TDE WALLET
--- tmux select-pane -t :.0
cd /opt/oracle/dcs/commonstore/wallets/$ORACLE_UNQNAME/tde
tar cvf /tmp/wallet.tar cwallet.sso ewallet.p12
ls -l /tmp/wallet.tar
cp $ORACLE_HOME/dbs/orapwchol23c /tmp
chmod 644 /tmp/orapwchol23c
exit
exit
scp hol23c0.dbhol23c:/tmp/wallet.tar /tmp
scp hol23c0.dbhol23c:/tmp/orapwchol23c /tmp
scp /tmp/wallet.tar hol23c1.dbhol23c:/tmp
scp /tmp/orapwchol23c hol23c1.dbhol23c:/tmp
rm /tmp/wallet.tar
rm /tmp/orapwchol23c
ssh opc@hol23c0.dbhol23c
sudo su - oracle
rm /tmp/wallet.tar
rm /tmp/orapwchol23c
--- tmux select-pane -t :.1
cd /opt/oracle/dcs/commonstore/wallets/$ORACLE_UNQNAME/tde
tar xvf /tmp/wallet.tar
cp /tmp/orapwchol23c $ORACLE_HOME/dbs
chmod 600 $ORACLE_HOME/dbs/orapwchol23c
exit
rm /tmp/wallet.tar
rm /tmp/orapwchol23c
sudo su - oracle
sqlplus / as sysdba
startup nomount force
exit
