# Installs the SoftLayer CLI
#pip install --upgrade pip
#pip install softlayer

KUBE_MASTER=kube-master
KUBE_NODE=kube-node
TIMEOUT=600

. ./kubernetes.cfg

# Args: $1: name
function create_server {
# Creates the machine
echo "Creating $1"
TEMP_FILE=/tmp/create-vs.out
yes | slcli vs create --hostname $1 --domain $DOMAIN --cpu 1 --memory 1 --datacenter $DATACENTER --billing hourly --os CENTOS_LATEST > $TEMP_FILE
}

# Args: $1: name
function create_kube {
# Check whether kube master exists
TEMP_FILE=/tmp/deploy-kubernetes.out
slcli vs list --hostname $1 --domain $DOMAIN | grep $1 > $TEMP_FILE
COUNT=`wc $TEMP_FILE | awk '{print $1}'`

# Determine whether to create the kube-master
if [ $COUNT -eq 0 ]; then
create_server $1
else
echo "$1 already created"
fi

# Wait kube master to be ready
echo "Waiting for virtual server $1 to be ready"
slcli vs ready $1 --wait=$TIMEOUT
}

function configure_master {
# Obtain the root password
slcli vs detail $KUBE_MASTER --passwords > $TEMP_FILE
PASSWORD=`grep root $TEMP_FILE | awk '{print $3}'`
echo PASSWORD $PASSWORD

# Obtain the IP address
IP_ADDRESS=`grep public_ip $TEMP_FILE | awk '{print $2}'`

# Generate SSH key
yes | ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$IP_ADDRESS

# Update ansible hosts file
ANSIBLE_CONFIG=./ansible/ansible.cfg
HOSTS=/tmp/ansible-hosts
echo > $HOSTS
echo "[kube-master]" >> $HOSTS
echo "$IP_ADDRESS ansible_user=root" >> $HOSTS

# Execute kube-master playbook
ansible-playbook ansible/kube-master.yaml
}

# Authenticates to SL
echo "[softlayer]" > ~/.softlayer
echo "username = $USER" >> ~/.softlayer
echo "api_key = $API_KEY" >> ~/.softlayer
echo "endpoint_url = https://api.softlayer.com/xmlrpc/v3.1/" >> ~/.softlayer
echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

create_kube $KUBE_MASTER
create_kube $KUBE_NODE

configure_master







