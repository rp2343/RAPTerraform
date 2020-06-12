#!/bin/bash
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum update -y
yum install -y strongswan
cd /usr/bin
sudo wget http://www.vdberg.org/~richard/tcpping
chmod 755 tcpping
systemctl enable strongswan
leftsubnet=$(ip route list |grep -i -m1 "/" | awk -F " " '{print $1}')
cat << EOF > /etc/strongswan/ipsec.conf
config setup
        # strictcrlpolicy=yes
        uniqueids = yes

conn host-to-host
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1

conn trap-any
    also=host-to-host
    right=%any
    leftsubnet=$leftsubnet
#    rightsubnet=10.1.2.0/24
    rightsubnet=%any
    type=transport
    authby=psk
    auto=route
EOF
systemctl start strongswan

secret=$(openssl rand -base64 24)

cat << EOF >> /etc/strongswan/ipsec.secrets
: PSK "$secret"
EOF
