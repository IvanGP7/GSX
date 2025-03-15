#!/bin/bash

echo "Configurando red..."
cat <<EOF > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp

auto eth1
iface   eth1 inet static
   address      192.0.2.1
   network      192.0.2.0
   netmask      255.255.255.0
   broadcast    192.0.2.255

auto eth2
iface   eth2 inet static
   address      172.25.0.1
   network      172.25.0.0
   netmask      255.255.0.0
   broadcast    172.25.0.255

EOF

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
ifdown eth1
ifup eth1
ifdown eth2
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
MASQ1="A POSTROUTING -s 192.0.2.0/24 -o eth0 -j MASQUERADE"
MASQ2="A POSTROUTING -s 172.25.0.0/16 -o eth0 -j MASQUERADE"

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
echo "Configurando Dnsmasq..."
cat << EOF > /etc/dnsmasq.conf
#/etc/dnsmasq.conf:  # DNS section

domain-needed	# blocks not FQDN
bogus-priv	# don't forward queries with private addresses

expand-hosts			# expands hostnames to FQDN

#private domain, never leaves your LAN
domain=dmz.gsx,192.0.2.0/24,local
domain=intranet.gsx,172.25.0.0/16,local

listen-address=127.0.0.1 
listen-address=192.0.2.1
listen-address=172.25.0.1
bind-interfaces		#  listen only to the addresses specificied above

# redirect bad domains:
address=/double-click.net/127.0.0.1
#no-hosts	# don't read /etc/hosts
#addn-hosts=/etc/banner_add_hosts	# add more hosts files

# set upstream DNS servers (forwarders)
server=8.8.8.8			# google DNS
server=1.1.1.1			# Cloudfare DNS

# DHCP section

# Ranges: exclude static IPs
dhcp-range=lan1,192.0.2.2,192.0.2.254,255.255.255.0,infinite # DMZ servers
dhcp-range=lan2,172.25.0.2,172.25.0.12,8h	# for 10 clients at intranet

# apply also options tagged as lan1 or lan2

# set default gateways
dhcp-option=lan1,3,192.0.2.1
dhcp-option=lan2,3,172.25.0.1

# set DNS servers
dhcp-option=lan1,option:dns-server,192.0.2.1
dhcp-option=lan1,option:domain-search,dmz.gsx,intranet.gsx
# options can be discovered by running "dnsmasq --help dhcp"
dhcp-option=lan2,6,172.25.0.1
dhcp-option=lan2,119,intranet.gsx,dmz.gsx

# known hosts: static IP & name
#dhcp-host=02:03:04:05:06:07,NOM,IP
# caveat: virtual machines may change MAC address

#dhcp-ignore=tag:!known	# == deny unkown-clients
EOF
systemctl restart dnsmasq
