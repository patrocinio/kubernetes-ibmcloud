# Installs the SoftLayer CLI
pip install --upgrade pip
pip install softlayer

KUBE_MASTER_PREFIX=kube-master-
KUBE_NODE_PREFIX=kube-node-
HOSTS=/tmp/ansible-hosts

# This var is not used anymore
TIMEOUT=600
PORT_SPEED=10


. ./kubernetes.cfg

# Set the server type
if [ $SERVER_TYPE  == "bare" ]; then
  SERVER_MESSAGE="bare metal server"
  CLI_TYPE=server
  SPEC="--size $SIZE --port-speed $PORT_SPEED --os CENTOS_7_64"
else
  SERVER_MESSAGE="virtual server"
  CLI_TYPE=vs
  SPEC="--cpu $CPU --memory $MEMORY --os CENTOS_LATEST"
fi

# Args: $1: VLAN number
function get_vlan_id {
   VLAN_ID=`slcli vlan list | grep $1 | awk '{print $1}'`
}

# Args: $1: label $2: VLAN number
function build_vlan_arg {
if [ -z $2 ]; then
    VLAN_ARG=""
  else
     get_vlan_id $2
     VLAN_ARG="$1 $VLAN_ID"
  fi
}

# Args: $1: name
function create_server {
# Creates the machine
echo "Creating $1 with $CPU cpu(s) and $MEMORY MB of RAM"
TEMP_FILE=/tmp/create-vs.out
build_vlan_arg "--vlan-private" $PRIVATE_VLAN
PRIVATE_ARG=$VLAN_ARG
build_vlan_arg "--vlan-public" $PUBLIC_VLAN
PUBLIC_ARG=$VLAN_ARG

echo "Deploying $SERVER_MESSAGE $1"
yes | slcli $CLI_TYPE create --hostname $1 --domain $DOMAIN $SPEC --datacenter $DATACENTER --billing hourly  $PRIVATE_ARG $PUBLIC_ARG | tee $TEMP_FILE
}

# Args: $1: name
function get_server_id {
# Extract virtual server ID
slcli $CLI_TYPE list --hostname $1 --domain $DOMAIN | grep $1 > $TEMP_FILE

# Consider only the first returned result
VS_ID=`head -1 $TEMP_FILE | awk '{print $1}'`
}

# Args: $1: name
function create_kube {
# Check whether kube master exists
TEMP_FILE=/tmp/deploy-kubernetes.out
slcli $CLI_TYPE list --hostname $1 --domain $DOMAIN | grep $1 > $TEMP_FILE
COUNT=`wc $TEMP_FILE | awk '{print $1}'`

# Determine whether to create the kube-master
if [ $COUNT -eq 0 ]; then
create_server $1
else
echo "$1 already created"
fi

get_server_id $1

# Wait kube master to be ready
while true; do
  STATE=`slcli $CLI_TYPE detail $VS_ID | grep state | awk '{ print $2}'`
echo "Waiting for $SERVER_MESSAGE $1 to be ready... State: $STATE"
  if [ $STATE == 'RUNNING' ]; then
    break
  else
    sleep 5
  fi
done
}

# Arg $1: hostname
function obtain_root_pwd {
get_server_id $1

# Obtain the root password
slcli $CLI_TYPE detail $VS_ID --passwords > $TEMP_FILE

# Remove "remote users"
PASSWORD=`grep root $TEMP_FILE | grep -v "remote users" | awk '{print $3}'`
echo PASSWORD $PASSWORD

}

# Args $1: hostname
function obtain_ip {
echo Obtaining IP address for $1
get_server_id $1
# Obtain the IP address
slcli $CLI_TYPE detail $VS_ID --passwords > $TEMP_FILE

if [ $CONNECTION  == "VPN" ]; then
  IP_ADDRESS=`grep private_ip $TEMP_FILE | awk '{print $2}'`
else
  IP_ADDRESS=`grep public_ip $TEMP_FILE | awk '{print $2}'`
fi
}

# From the standpoint of ansible, kube-master-2 is a 'node'
function update_hosts_file {
# Update ansible hosts file
echo Updating ansible hosts files
echo > $HOSTS
echo "[kube-master]" >> $HOSTS
obtain_ip ${KUBE_MASTER_PREFIX}1
MASTER1_IP=$IP_ADDRESS
echo "kube-master-1 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
#echo "$IP_ADDRESS ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS

obtain_ip ${KUBE_MASTER_PREFIX}2
MASTER2_IP=$IP_ADDRESS
# Multiple masters work
# echo "kube-master-2 ansible_host=$MASTER2_IP ansible_user=root" >> $HOSTS


echo "[kube-node]" >> $HOSTS
obtain_ip "${KUBE_NODE_PREFIX}1"
NODE1_IP=$IP_ADDRESS
echo "kube-node-1 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
#echo "$IP_ADDRESS ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
obtain_ip "${KUBE_NODE_PREFIX}2"
NODE2_IP=$IP_ADDRESS
echo "kube-node-2 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
#echo "$IP_ADDRESS ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
}

#Args: $1: master hostname $2: master IP
function configure_master {
# Get kube master password
obtain_root_pwd $1

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$2

# Create inventory file
INVENTORY=/tmp/inventory
echo > $INVENTORY
echo "[masters]" >> $INVENTORY
echo "kube-master-1" >> $INVENTORY
#echo "kube-master-2" >> $INVENTORY
echo >> $INVENTORY
echo "[etcd]" >> $INVENTORY
echo "kube-master-1" >> $INVENTORY
#echo "kube-master-2" >> $INVENTORY
echo >> $INVENTORY
echo "[nodes]" >> $INVENTORY
echo "$NODE1_IP" >> $INVENTORY
echo "$NODE2_IP" >> $INVENTORY

# Create ansible.cfg
ANSIBLE_CFG=/tmp/ansible.cfg
echo > $ANSIBLE_CFG
echo "[defaults]" >> $ANSIBLE_CFG
echo "host_key_checking = False" >> $ANSIBLE_CFG

}

function configure_masters {
  configure_master ${KUBE_MASTER_PREFIX}1 $MASTER1_IP
  configure_master ${KUBE_MASTER_PREFIX}2 $MASTER2_IP

  # Execute kube-master playbook
  ansible-playbook -i $HOSTS ansible/kube-master.yaml --extra-vars "kube_node1=$NODE1_IP kube_node2=$NODE2_IP kube_master2=$MASTER2_IP"
}

# Args $1 Node name
function configure_node {
echo Configuring node $1

# Get kube master password
obtain_root_pwd $1

# Get master IP address
obtain_ip $1
NODE_IP=$IP_ADDRESS
echo IP Address: $NODE_IP

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$NODE_IP
}

function configure_nodes {
echo Configuring nodes
configure_node "${KUBE_NODE_PREFIX}1"
configure_node "${KUBE_NODE_PREFIX}2"

# Execute kube-master playbook
ansible-playbook -i $HOSTS ansible/kube-node.yaml
}

function create_nodes {
create_kube "${KUBE_NODE_PREFIX}1"
create_kube "${KUBE_NODE_PREFIX}2"
}

function create_masters {
create_kube "${KUBE_MASTER_PREFIX}1"
create_kube "${KUBE_MASTER_PREFIX}2"

}

#function configure_secondary_master {
# Execute kube-secondary-master playbook
#ansible-playbook ansible/kube-secondary-master.yaml --extra-vars "kube_node1=$NODE1_IP kube_node2=$NODE2_IP kube_master1=$MASTER1_IP"
#}

# Authenticates to SL
echo "[softlayer]" > ~/.softlayer
echo "username = $USER" >> ~/.softlayer
echo "api_key = $API_KEY" >> ~/.softlayer
echo "endpoint_url = $ENDPOINT" >> ~/.softlayer
echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

create_nodes
create_masters

# Generate SSH key
#yes | ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

update_hosts_file

configure_nodes
#configure_secondary_master
configure_masters

echo "Congratulations! You can log on to the kube masters by issuing ssh root@$MASTER1_IP"







