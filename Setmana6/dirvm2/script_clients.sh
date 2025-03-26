#!/bin/bash

if ! grep "^require domain-name, domain-name-servers;" /etc/dhcp/dhclient.conf;then
	echo "Añadiendo domain-name y domain-name-servers en dhclient"
	echo "require domain-name, domain-name-servers;" >> /etc/dhcp/dhclient.conf
else
	echo "Config dhclient hecha"
fi

cat << EOF > /etc/resolv.conf
domain intranet.gsx
search intranet.gsx dmz.gsx
nameserver 192.0.2.2
EOF
chattr +i /etc/resolv.conf
cp ./actualitza_nom_local /etc/dhcp/dhclient-exit-hooks.d/

chmod 777 /etc/dhcp/dhclient-exit-hooks.d/actualitza_nom_local

ifdown eth0
ifup eth0

# 7. Verificar configuración
echo "Configuración aplicada:"
echo "MAC: $(cat /sys/class/net/eth0/address)"
echo "IP: $(hostname -I)"
echo "Hostname: $(hostname)"
