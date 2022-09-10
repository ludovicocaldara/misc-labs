GNS_IP=${gns_ip}
HA_VIP=${ha_vip}


# DBCS uses iptables and not firewalld
systemctl stop iptables
systemctl disable iptables

# disable client timeout via ssh
sed -i /^ClientAliveInterval/d /etc/ssh/sshd_config
systemctl restart sshd

GI_HOME=$(cat /etc/oracle/olr.loc 2>/dev/null | grep crs_home | awk -F= '{print $2}')
GI_VERSION=$($GI_HOME/bin/oraversion -compositeVersion)

$GI_HOME/bin/asmcmd setattr -G DATA compatible.asm $GI_VERSION

$GI_HOME/bin/srvctl add gns -vip $GNS_IP
$GI_HOME/bin/srvctl start gns

#$GI_HOME/bin/srvctl add havip -id rhphavip -address $HA_VIP

$GI_HOME/bin/srvctl stop rhpserver
$GI_HOME/bin/srvctl remove rhpserver

$GI_HOME/bin/srvctl add rhpserver -storage /rhp_storage -diskgroup DATA
$GI_HOME/bin/srvctl start rhpserver
#echo
#echo '=== Enabling NFS SERVER ===' 
#echo 
#systemctl enable nfs-server
#systemctl start nfs-server

sudo -u grid $GI_HOME/bin/srvctl modify rhpserver -pl_port 8900
sudo -u grid $GI_HOME/bin/srvctl modify rhpserver -port_range 8901-8906
