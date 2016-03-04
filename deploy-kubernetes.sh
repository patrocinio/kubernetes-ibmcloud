# Installs the SoftLayer CLI
#pip install --upgrade pip
#pip install softlayer

KUBE_MASTER=kube-master
TIMEOUT=600

. ./kubernetes.cfg

function create_master {
# Creates the kube master
echo "Creating kube master"
TEMP_FILE=/tmp/create-vs.out
yes | slcli vs create --hostname kube-master --domain $DOMAIN --cpu 1 --memory 1 --datacenter $DATACENTER --billing hourly --os CENTOS_LATEST > $TEMP_FILE
VS_ID=`grep -o "\bid.*\b" $TEMP_FILE | head -1 | awk '{print $2}'`

echo "Waiting for virtual server $VS_ID to be ready"
slcli vs ready $VS_ID --wait=$TIMEOUT
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
TEMP_FILE=/tmp/deploy-kubernetes.out
slcli vs list --hostname $KUBE_MASTER --domain $DOMAIN > $TEMP_FILE
COUNT=`wc $TEMP_FILE | awk '{print $1}'`

# There is always an empty line
if [ $COUNT -eq 1 ]; then
  create_master
else
  echo "kube-master already created"
fi




