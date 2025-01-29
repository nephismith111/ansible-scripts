# install Elastic and Kibana
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
sudo apt-get install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update && sudo apt-get install elasticsearch kibana unzip -y

# Setup certificates  RpbJCMqJ2g
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca -pem
sudo mv /usr/share/elasticsearch/elastic-stack-ca.zip /etc/elasticsearch/certs/
sudo unzip -d /etc/elasticsearch/certs /etc/elasticsearch/certs/elastic-stack-ca.zip
sudo ls /etc/elasticsearch/certs/ca/

sudo /usr/share/elasticsearch/jdk/bin/keytool -importcert -trustcacerts -noprompt -keystore /etc/elasticsearch/certs/elastic-stack-ca.p12 -storepass RpbJCMqJ2g -alias new-ca -file /etc/elasticsearch/certs/ca/ca.crt
/usr/share/elasticsearch/jdk/bin/keytool -keystore elastic-stack-ca.p12 -list

sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca-cert /etc/elasticsearch/certs/ca/ca.crt --ca-key /etc/elasticsearch/certs/ca/ca.key
sudo mv /usr/share/elasticsearch/elastic-certificates.p12 /etc/elasticsearch/certs/
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore list

# Remove passwords
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore remove xpack.security.transport.ssl.keystore.secure_password
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore remove xpack.security.transport.ssl.truststore.secure_password


# encryption stuff for kibana


/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana


sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service

# Copy over the kibana.yml file to /etc/kibana/kibana.yml

sudo systemctl start kibana
sudo systemctl enable kibana


# Get a token for kibana
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana


##### Setup https
# Copy over the root ca from vault to /usr/local/share/ca-certificates/root-ca.crt
sudo update-ca-certificates  # to apply the changes
sudo /usr/share/elasticsearch/jdk/bin/keytool -importcert -trustcacerts -noprompt -keystore /etc/elasticsearch/certs/ns-elastic-ca.p12 -storepass RpbJCMqJ2g -alias new-ca -file /usr/local/share/ca-certificates/root-ca.crt

# Build the keystore (since the truststore is now done).
openssl pkcs12 -export -in certs/elastic.crt -inkey certs/elastic.key -CAfile certs/root-ca.crt -chain -out certs/elastic.p12 -name elastic
openssl pkcs12 -export -in certs/ssl.crt -inkey certs/ssl.key -CAfile certs/root-ca.crt -chain -out certs/ssl.p12 -name ssl
# Copy to elastic server at /etc/elasticsearch/certs/elastic.p12


# confirm the certificate went in. You'll need the password again
/usr/share/elasticsearch/jdk/bin/keytool -keystore /etc/elasticsearch/certs/ns-elastic-ca.p12 -list
/usr/share/elasticsearch/jdk/bin/keytool -keystore /etc/elasticsearch/certs/elastic.p12 -list
/usr/share/elasticsearch/jdk/bin/keytool -keystore /etc/elasticsearch/certs/ssl.p12 -list

/usr/share/elasticsearch/jdk/bin/keytool -keystore /etc/elasticsearch/elasticsearch.keystore -list


# Stop elasticsearch
sudo systemctl stop elasticsearch.service

# observe the existing passwords
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore list
# remove existingpasswords
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore remove xpack.security.transport.ssl.keystore.secure_password
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore remove xpack.security.transport.ssl.truststore.secure_password
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore remove xpack.security.http.ssl.keystore.secure_password

# add new passwords: RpbJCMqJ2g

sudo /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password
sudo /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.http.ssl.keystore.secure_password



# Setup kibana
/usr/share/kibana/bin/kibana-encryption-keys generate    # generate encryption keys

