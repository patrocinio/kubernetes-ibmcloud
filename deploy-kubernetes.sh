# Installs the SoftLayer CLI
#pip install --upgrade pip
#pip install softlayer

. ./deploy-kubernetes.cfg

function create_master {
# Creates the kube master
#yes | slcli vs create --hostname kube-master --domain $DOMAIN --cpu 1 --memory 1 --datacenter $DATACENTER --billing hourly --os CENTOS_LATEST
 echo "Creating kube master"
}

# Authenticates to SL
echo "[softlayer]" > ~/.softlayer
echo "username = $USER" >> ~/.softlayer
echo "api_key = $API_KEY" >> ~/.softlayer
echo "endpoint_url = https://api.softlayer.com/xmlrpc/v3.1/" >> ~/.softlayer
echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

# Check whether kube master exists
KUBE_MASTER=kube-master
TEMP_FILE=/tmp/deploy-kubernetes.out
slcli vs list --hostname $KUBE_MASTER --domain $DOMAIN > $TEMP_FILE
COUNT=`wc $TEMP_FILE | awk '{print $1}'`
if [ $COUNT -eq 0 ]; then
  create_master
else
  echo "kube-master already created"
fi



