if [ -z "$1" ]; then
    echo "please provide arguments: ./client-to-node.sh <password>"
    exit
fi
echo -------------------------------------------------------------------------
echo ---- This script will set up client security for you on this node    ----
echo ---- hit return to execute each step                                 ----
echo -------------------------------------------------------------------------
echo
echo -------------------------------------------------------------------------
echo -----------------------------create files--------------------------------
echo -------------------------------------------------------------------------
read -r
sudo mkdir /etc/dse/certs

cd /etc/dse/certs || exit

echo -------------------------------------------------------------------------
echo -----------------------set up up keystore--------------------------------
echo -------------------------------------------------------------------------
read -r

#keystore
sudo keytool -genkey -alias keystore -keyalg RSA -keysize 1024 -dname "CN=UNKNOWN, OU=UNKNOWN, O=UNKNOWN, C=UNKNOWN"  -keystore .keystore -storepass "$1" -keypass "$1"


echo -------------------------------------------------------------------------
echo -------------------------set up certs------------------------------------
echo -------------------------------------------------------------------------
read -r

#certificate
sudo keytool -export -alias keystore -file dse_node0.cer -keystore .keystore -storepass "$1" -keypass "$1"

echo -------------------------------------------------------------------------
echo ------------------------set up truststore--------------------------------
echo -------------------------------------------------------------------------
read -r

#truststore
sudo keytool -import -v -noprompt -trustcacerts -alias cassandra-secure1 -file dse_node0.cer -keystore .truststore -storepass "$1"

echo -------------------------------------------------------------------------
echo ------------------------set up user key and pem--------------------------
echo -------------------------------------------------------------------------
read -r
sudo keytool -importkeystore -srckeystore .keystore -destkeystore user.p12 -deststoretype PKCS12  --srcstorepass "$1" --deststorepass "$1"

sudo openssl pkcs12 -in user.p12 -out user.pem -nodes -password pass:"$1"


echo ----------Here are your keystore, truststores, and keys------------------
ls -lah

echo -------------------------------------------------------------------------
echo ------------ Create/overwrite your cqlshrc file -------------------------
echo -------------------------------------------------------------------------


sudo echo "
[authentication]
username =
password =
[connection]
factory = cqlshlib.ssl.ssl_transport_factory
[ssl]
certfile = /etc/dse/certs/user.pem
validate = true ## Optional, true by default." | sudo tee ~/.cassandra/cqlshrc


echo -------------------------------------------------------------------------

read -r

echo -------------------------------------------------------------------------
echo ------------MANUAL STEP - For client to node configure:------------------
echo -------------------------------------------------------------------------

echo
echo ---- Modify your cassandra.yaml use ctrl-z to background the process ----
echo ---- fg to come back to this process and hit enter once you are back  ----
echo

echo "     sudo vim /etc/dse/cassandra/cassandra.yaml"
echo "     "
echo "     client_encryption_options:"
echo "       keystore: /etc/dse/certs/.keystore"
echo "       truststore_password: $1"
echo "       cipher_suites: [TLS_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_RSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA]"
echo "       enabled: true"
echo "       protocol: TLS"
echo "       require_client_auth: false"
echo "       truststore: /etc/dse/certs/.truststore"
echo "       keystore_password: $1"


echo -------------------------------------------------------------------------

read -r

echo -------------------------------------------------------------------------
echo -------------------------- Restart DSE  ---------------------------------
echo -------------------------------------------------------------------------
echo ------wait until Listening for thift before hitting enter  --------------
sudo service dse restart
tail -f /var/log/cassandra/system.log | grep "Listening for thrift clients" & read -r
echo -------------------------------------------------------------------------
echo -------------------------- nodetool status  -----------------------------
echo -------------------------------------------------------------------------

nodetool status

echo -------------------------------------------------------------------------
echo ------------Testing CQLSH -- should output number of peers   ------------
echo -------------------------------------------------------------------------

cqlsh --ssl -e "select count(1) from system.peers"
read -r
echo ALL DONE!
