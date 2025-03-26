#!/bin/bash


if ! dpkg -l | grep -q "apache2";then
        apt-get update
        apt install -y apache2
else
        echo "Apache2 ya esta instalado"
fi


MAC_ADDR="86:df:50:46:29:c3"
ip link set dev eth0 address $MAC_ADDR

if ! grep "^require domain-name, domain-name-servers;" /etc/dhcp/dhclient.conf;then
        echo "require domain-name, domain-name-servers;" >> /etc/dhcp/dhclient.conf
fi

cp ./actualitza_nom_local /etc/dhcp/dhclient-exit-hooks.d/

chmod 777 /etc/dhcp/dhclient-exit-hooks.d/actualitza_nom_local
ifdown eth0
ifup eth0

# 7. Verificar configuración
echo "Configuración aplicada:"
echo "MAC: $(cat /sys/class/net/eth0/address)"
echo "IP: $(hostname -I)"
echo "Hostname: $(hostname)"
