#!/bin/bash

if ! grep "^require domain-name, domain-name-servers;" /etc/dhcp/dhclient.conf;then
	echo "Añadiendo domain-name y domain-name-servers en dhclient"
	echo "require domain-name, domain-name-servers;" >> /etc/dhcp/dhclient.conf
else
	echo "Config dhclient hecha"
fi
ifdown eth0
ifup eth0

cat << EOF > /etc/resolv.conf
domain intranet.gsx
search intranet.gsx dmz.gsx
nameserver 192.0.2.2
EOF

