# Installs the SoftLayer CLI
#pip install --upgrade pip
#pip install softlayer

. ./kubernetes.cfg

# Authenticates to SL
#echo "[softlayer]" > ~/.softlayer
#echo "username = $USER" >> ~/.softlayer
#echo "api_key = $API_KEY" >> ~/.softlayer
#echo "endpoint_url = https://api.softlayer.com/xmlrpc/v3.1/" >> ~/.softlayer
#echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

# Set the server type
if [ $SERVER_TYPE  == "bare" ]; then
  CLI_TYPE=server
  echo "command currently only supports imaging virtual servers."
  exit 1
else
  CLI_TYPE=vs
fi

TEMP_FILE=/tmp/image_kubernetes.out
slcli $CLI_TYPE list --domain $DOMAIN > $TEMP_FILE
while read l; do
   serverid="$(echo $l | cut -d " " -f 1)"
   servername="$(echo $l | cut -d " " -f 2)"
   d=$(date +%Y-%m-%d-%H:%M:%S)
   echo Imaging server $serverid
   echo "slcli $CLI_TYPE capture -n '$servername image taken at $d' --all YES $serverid"
   slcli $CLI_TYPE capture -n "$servername image taken at $d" --all YES $serverid
done <$TEMP_FILE
