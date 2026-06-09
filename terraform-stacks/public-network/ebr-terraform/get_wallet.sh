# This script wipes out $HOME/instantclient and $HOME/demoadb
# Don't run it if you are not OK with it :-)
# It must be executed after the terraform stack is deployed locally (not with OCI Resource Manager)
# as it requires the output variables to be readable to set up everything.
#
# This script:
# - get the ADB password
# - it downloads the ADB wallet and unzip it in $HOME/demoadb
# - it downloads and unzip the latest instantclient in $HOME/instantclient
# - it symlinks network/admin to demoadb where the wallet has been unzipped

if [ -z "$COMPARTMENT_OCID" ] ; then
    echo "COMPARTMENT_OCID variable not set"
    exit
fi
export ADB_OCID=$(oci db autonomous-database list --compartment-id $COMPARTMENT_OCID  | jq -r '.data[] | select(."db-name"=="demoadb") | .id')

export ADB_PASSWORD=$(echo 'nonsensitive(random_password.adb_password.result)' | terraform console)
export WLT_PASSWORD=$(echo 'nonsensitive(random_password.adb_wallet_password.result)' | terraform console)

echo $ADB_OCID
echo $ADB_PASSWORD
echo $WLT_PASSWORD


TMP_WALLET=$(mktemp)
CONFIG_DIR=$HOME/demoadb

oci db autonomous-database generate-wallet --password $ADB_PASSWORD --autonomous-database-id $ADB_OCID --file $TMP_WALLET
[ -d $CONFIG_DIR ] && rm -rf $CONFIG_DIR
mkdir $CONFIG_DIR
cd $CONFIG_DIR
unzip $TMP_WALLET && rm $TMP_WALLET


if [ `uname -m` == "aarch64" ] ; then
    IC_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linux-arm64.zip
else
    IC_URL=https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip
fi

wget $IC_URL -O $HOME/instantclient.zip

IC_TMPLOC=$(mktemp -d)
cd $IC_TMPLOC
unzip $HOME/instantclient.zip
[ -d $HOME/instantclient ] && rm -rf $HOME/instantclient
mv $IC_TMPLOC/inst* $HOME/instantclient
rm $HOME/instantclient.zip

rm -rf $HOME/instantclient/network/admin
ln -s $CONFIG_DIR $HOME/instantclient/network/admin

cat <<EOF >> $HOME/.bash_profile
export ADB_PASSWORD="$ADB_PASSWORD"
export LD_LIBRARY_PATH=$HOME/instantclient
EOF

echo "source your .bash_profile to get PASSWORD and LD_LIBRARY_PATH in the environment"
