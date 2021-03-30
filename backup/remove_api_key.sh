echo Cleaning the SoftLayer API Key
cp kubernetes.cfg ~
TEMP_FILE=/tmp/kubernetes.cfg
sed 's/\(API_KEY=\).*/\1/' kubernetes.cfg > $TEMP_FILE
mv $TEMP_FILE kubernetes.cfg


