#!/bin/bash
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum update -y
yum install -y strongswan iperf3 qperf httpd git autoconf automake gcc-c++
cd /usr/bin
sudo wget http://www.vdberg.org/~richard/tcpping
chmod 755 tcpping
cd ~; git clone https://github.com/Mellanox/sockperf.git
cd sockperf; ./autogen.sh; ./configure; make; make install; mv sockperf /usr/local/bin; cd ~
firewall-offline-cmd --add-port=5201/tcp --add-port=80/tcp --add-port=19765/tcp --add-port=19766/tcp --add-port=12345/tcp 
systemctl enable firewalld; systemctl restart firewalld

certfilename=certificate
keyfilename=privatekey
keyvault="https://kvbripsec.vault.azure.net/"
certificatename=bripseccert

accesstoken=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq -r '.access_token')

echo "-----BEGIN CERTIFICATE-----" | sudo tee /etc/strongswan/ipsec.d/certs/$certfilename.pem
curl -s $keyvault/certificates/$certificatename?api-version=2016-10-01 -H "Authorization: Bearer $accesstoken" | jq -r '.cer' | sudo tee -a /etc/strongswan/ipsec.d/certs/$certfilename.pem
echo "-----END CERTIFICATE-----" | sudo tee -a /etc/strongswan/ipsec.d/certs/$certfilename.pem

curl -s $keyvault/secrets/$certificatename?api-version=2016-10-01 -H "Authorization: Bearer $accesstoken" | jq -r '.value' | sudo tee /etc/strongswan/ipsec.d/private/$keyfilename.pem
sudo sed -Ei "/-----BEGIN CERTIFICATE/,/END CERTIFICATE-----/d" /etc/strongswan/ipsec.d/private/$keyfilename.pem

echo ": RSA /etc/strongswan/ipsec.d/private/$keyfilename.pem" | sudo tee -a /etc/strongswan/ipsec.secrets

sudo sed -Ei "s/leftcert=([a-zA-Z0-9]+.pem)/leftcert=$certfilename.pem/g" /etc/strongswan/ipsec.conf
sudo sed -Ei "s/rightcert=([a-zA-Z0-9]+.pem)/rightcert=$certfilename.pem/g" /etc/strongswan/ipsec.conf

sudo strongswan rereadsecrets
sudo strongswan update


leftsubnet=$(ip route list |grep -i -m1 "/" | awk -F " " '{print $1}')
cat << EOF > /etc/strongswan/ipsec.conf
config setup
        # strictcrlpolicy=yes
        uniqueids = yes
        charondebug="all"

conn %default
        keyexchange=ikev2
        ike=aes128-sha256-ecp256,aes256-sha384-ecp384,aes128-sha256-modp2048,aes128-sha1-modp2048,aes256-sha384-modp4096,aes256-sha256-modp4096,aes256-sha1-modp4096,aes128-sha256-modp1536,aes128-sha1-modp1536,aes256-sha384-modp2048,aes256-sha256-modp2048,aes256-sha1-modp2048,aes128-sha256-modp1024,aes128-sha1-modp1024,aes256-sha384-modp1536,aes256-sha256-modp1536,aes256-sha1-modp1536,aes256-sha384-modp1024,aes256-sha256-modp1024,aes256-sha1-modp1024!
        esp=aes128gcm16-ecp256,aes256gcm16-ecp384,aes128-sha256-ecp256,aes256-sha384-ecp384,aes128-sha256-modp2048,aes128-sha1-modp2048,aes256-sha384-modp4096,aes256-sha256-modp4096,aes256-sha1-modp4096,aes128-sha256-modp1536,aes128-sha1-modp1536,aes256-sha384-modp2048,aes256-sha256-modp2048,aes256-sha1-modp2048,aes128-sha256-modp1024,aes128-sha1-modp1024,aes256-sha384-modp1536,aes256-sha256-modp1536,aes256-sha1-modp1536,aes256-sha384-modp1024,aes256-sha256-modp1024,aes256-sha1-modp1024,aes128gcm16,aes256gcm16,aes128-sha256,aes128-sha1,aes256-sha384,aes256-sha256,aes256-sha1!
        dpdaction=clear
        dpddelay=300s
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1

# to access the host via SSH in the test environment
conn pass-ssh
        authby=never
        leftsubnet=0.0.0.0/0[tcp/22]
        rightsubnet=0.0.0.0/0[tcp]
        type=pass
        auto=route

conn trap-any
        rightsubnet=10.0.0.0/8
        rightcert=certificate2.pem
        leftsubnet=10.0.0.0/8
        leftcert=certificate2.pem
        type=transport
        auto=route

EOF

# systemctl start strongswan
# systemctl enable strongswan
#secret=$(openssl rand -base64 24)

cat << EOF >> /etc/strongswan/ipsec.secrets
: PSK "Microsoft1234$"
EOF

cat << EOF > /home/adminuser/rotate-certs.sh

certfilename=certificate2
keyfilename=privatekey2
keyvault="https://kvbripsec.vault.azure.net/"
certificatename=bripseccert

accesstoken=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq -r '.access_token')

echo "-----BEGIN CERTIFICATE-----" | sudo tee /etc/strongswan/ipsec.d/certs/$certfilename.pem
curl -s $keyvault/certificates/$certificatename?api-version=2016-10-01 -H "Authorization: Bearer $accesstoken" | jq -r '.cer' | sudo tee -a /etc/strongswan/ipsec.d/certs/$certfilename.pem
echo "-----END CERTIFICATE-----" | sudo tee -a /etc/strongswan/ipsec.d/certs/$certfilename.pem

curl -s $keyvault/secrets/$certificatename?api-version=2016-10-01 -H "Authorization: Bearer $accesstoken" | jq -r '.value' | sudo tee /etc/strongswan/ipsec.d/private/$keyfilename.pem
sudo sed -Ei "/-----BEGIN CERTIFICATE/,/END CERTIFICATE-----/d" /etc/strongswan/ipsec.d/private/$keyfilename.pem

echo ": RSA /etc/strongswan/ipsec.d/private/$keyfilename.pem" | sudo tee -a /etc/strongswan/ipsec.secrets

sudo sed -Ei "s/leftcert=([a-zA-Z0-9]+.pem)/leftcert=$certfilename.pem/g" /etc/strongswan/ipsec.conf
sudo sed -Ei "s/rightcert=([a-zA-Z0-9]+.pem)/rightcert=$certfilename.pem/g" /etc/strongswan/ipsec.conf

sudo strongswan rereadsecrets
sudo strongswan update

EOF

# Adding local cloud user to sudoers group 
user=`cat /etc/passwd |grep -i "Cloud User" |awk -F: '{print $1}'`
usermod -aG wheel $user
cat << EOF > /etc/sudoers.d/clouduser_sudo
$user ALL=(ALL) NOPASSWD: ALL
EOF
