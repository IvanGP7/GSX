#!/bin/bash

echo "Configurando red..."
if ! grep "^auto eth1" /etc/network/interfaces; then
cat <<EOF >> /etc/network/interfaces

auto eth1
iface	eth1 inet static
   address	192.0.2.1
   network	192.0.2.0
   netmask	255.255.255.0
   broadcast	192.0.2.255

auto eth2
iface   eth2 inet static
   address      172.25.0.1
   network      172.25.0.0
   netmask      255.255.0.0
   broadcast    172.25.0.255

EOF
fi

cat <<EOF > /etc/network/interfaces.d/eth1

auto    eth1
iface   eth1 inet static
   address      192.0.2.1
   network      192.0.2.0
   netmask      255.255.255.0
   broadcast    192.0.2.255
EOF

cat <<EOF > /etc/network/interfaces.d/eth2

auto    eth2
iface   eth2 inet static
   address      172.25.0.1
   network      172.25.0.0
   netmask      255.255.0.0
   broadcast    172.25.0.255

EOF



echo ""
echo "Status Interfaces"
cat /etc/network/interfaces
echo "*****************"
echo ""

echo "Iniciando Ifup"
ifup eth1
ifup eth2
echo ""
echo "Activando ip_forward"
if ! grep "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
	echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
	sudo sysctl -p
fi
cat /etc/sysctl.conf | grep "net.ipv4.ip_forward=1"
echo "Forward ipv4 activado"
echo ""

echo "Activando Masquerades"
# Definir las reglas que queremos verificar
MASQ1="*nat.*-A POSTROUTING -s 192.0.2.0/24 -o eth0 -j MASQUERADE"
MASQ2="*nat.*-A POSTROUTING -s 172.25.0.0/16 -o eth0 -j MASQUERADE"

# Verificar si las reglas ya están presentes
if ! iptables-save | grep -q -E "$MASQ1"; then
    echo "Añadiendo regla 1: 192.0.2.0/24 -> MASQUERADE"
    iptables -t nat -A POSTROUTING -s 192.0.2.0/24 -o eth0 -j MASQUERADE
else
    echo "La regla 1 ya está activa."
fi

if ! iptables-save | grep -q -E "$MASQ2"; then
    echo "Añadiendo regla 2: 172.25.0.0/16 -> MASQUERADE"
    iptables -t nat -A POSTROUTING -s 172.25.0.0/16 -o eth0 -j MASQUERADE
else
    echo "La regla 2 ya está activa."
fi

echo "Proceso completado."

echo "Configurando HOSTS"

cat << EOF > /etc/hosts
127.0.0.1   localhost
127.0.1.1   vm0
192.0.2.1   vm1
172.25.0.1  vm2

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

cat << EOF > /etc/resolv.conf
search intranet.gsx dmz.gsx
nameserver 127.0.0.1
EOF
systemctl restart dnsmasq
