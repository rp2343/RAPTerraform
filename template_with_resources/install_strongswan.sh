#!/bin/bash
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum update -y
yum install -y strongswan
cd /usr/bin
sudo wget http://www.vdberg.org/~richard/tcpping
chmod 755 tcpping
yum install -y iperf3
firewall-cmd --add-port=5201/tcp
leftsubnet=$(ip route list |grep -i -m1 "/" | awk -F " " '{print $1}')
cat << EOF > /etc/strongswan/ipsec.conf
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
        # strictcrlpolicy=yes
        uniqueids = yes
        charondebug="all"

# Add connections here.

conn host-to-host
    keyexchange=ikev2
    ike=aes128-sha256-ecp256,aes256-sha384-ecp384,aes128-sha256-modp2048,aes128-sha1-modp2048,aes256-sha384-modp4096,aes256-sha256-modp4096,aes256-sha1-modp4096,aes128-sha256-modp1536,aes128-sha1-modp1536,aes256-sha384-modp2048,aes256-sha256-modp2048,aes256-sha1-modp2048,aes128-sha256-modp1024,aes128-sha1-modp1024,aes256-sha384-modp1536,aes256-sha256-modp1536,aes256-sha1-modp1536,aes256-sha384-modp1024,aes256-sha256-modp1024,aes256-sha1-modp1024!
    esp=aes128gcm16-ecp256,aes256gcm16-ecp384,aes128-sha256-ecp256,aes256-sha384-ecp384,aes128-sha256-modp2048,aes128-sha1-modp2048,aes256-sha384-modp4096,aes256-sha256-modp4096,aes256-sha1-modp4096,aes128-sha256-modp1536,aes128-sha1-modp1536,aes256-sha384-modp2048,aes256-sha256-modp2048,aes256-sha1-modp2048,aes128-sha256-modp1024,aes128-sha1-modp1024,aes256-sha384-modp1536,aes256-sha256-modp1536,aes256-sha1-modp1536,aes256-sha384-modp1024,aes256-sha256-modp1024,aes256-sha1-modp1024,aes128gcm16,aes256gcm16,aes128-sha256,aes128-sha1,aes256-sha384,aes256-sha256,aes256-sha1!
    dpdaction=clear
    dpddelay=300s
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1

conn trap-any
    also=host-to-host
#    left=10.1.2.4
    right=%any
    leftsubnet=$leftsubnet
    rightsubnet=$leftsubnet
    type=transport
    auto=route

EOF
# systemctl start strongswan
# systemctl enable strongswan
#secret=$(openssl rand -base64 24)

cat << EOF >> /etc/strongswan/ipsec.secrets
: PSK "Microsoft1234$"
EOF
