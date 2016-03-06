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
#yes | slcli vs create --hostname $KUBE_MASTER --domain $DOMAIN --cpu 1 --memory 1 --datacenter $DATACENTER --billing hourly --os CENTOS_LATEST > $TEMP_FILE
#VS_ID=`grep -o "\bid.*\b" $TEMP_FILE | head -1 | awk '{print $2}'`

echo "Waiting for virtual server $KUBE_MASTER to be ready"
slcli vs ready $KUBE_MASTER --wait=$TIMEOUT
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
slcli vs list --hostname $KUBE_MASTER --domain $DOMAIN | grep $KUBE_MASTER > $TEMP_FILE
COUNT=`wc $TEMP_FILE | awk '{print $1}'`

# Determine whether to create the kube-master
if [ $COUNT -eq 0 ]; then
  create_master
else
  echo "kube-master already created"
fi

# Obtain the root password
slcli vs detail $KUBE_MASTER --passwords > $TEMP_FILE
PASSWORD=`grep root $TEMP_FILE | awk '{print $3}'`
echo PASSWORD $PASSWORD

# Obtain the IP address
set -x
IP_ADDRESS=`grep public_ip $TEMP_FILE | awk '{print $2}'`

# Generate SSH key
yes | ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$IP_ADDRESS

# Test connection
ssh root@$IP_ADDRESS whoami






