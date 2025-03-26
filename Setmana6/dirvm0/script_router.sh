#!/bin/bash
dpkg -l | grep -q "ii  dnsmasq"
if [ $? != 0];then
	apt-get update
	apt-get install -y dnsmasq
else
	echo "Dnsmasq ya esta instalado"
fi


echo "router" > /etc/hostname
hostname -F /etc/hostname
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
ifdown eth1 > /dev/null
ifup eth1 > /dev/null
ifdown eth2 > /dev/null
ifup eth2 > /dev/null
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

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

cat << EOF > /etc/resolv.conf
search intranet.gsx dmz.gsx
nameserver 192.0.2.2
EOF
echo "Configurando Dnsmasq..."
cat << EOF > /etc/dnsmasq.conf
#/etc/dnsmasq.conf:  # DNS section

#domain-needed	# blocks not FQDN
#bogus-priv	# don't forward queries with private addresses

#expand-hosts			# expands hostnames to FQDN

#private domain, never leaves your LAN
#domain=dmz.gsx,192.0.2.0/24,local
#domain=intranet.gsx,172.25.0.0/16,local

#listen-address=127.0.0.1
#listen-address=192.0.2.1
#listen-address=172.25.0.1
#bind-interfaces		#  listen only to the addresses specificied above

# redirect bad domains:
#address=/double-click.net/127.0.0.1
#no-hosts	# don't read /etc/hosts
#addn-hosts=/etc/banner_add_hosts	# add more hosts files

# set upstream DNS servers (forwarders)
#server=8.8.8.8			# google DNS
#server=1.1.1.1			# Cloudfare DNS

# DHCP section

# Ranges: exclude static IPs
dhcp-range=lan1,192.0.2.2,192.0.2.254,255.255.255.0,infinite # DMZ servers
dhcp-range=lan2,172.25.0.2,172.25.0.11,8h	# for 10 clients at intranet

# apply also options tagged as lan1 or lan2

# set default gateways
dhcp-option=lan1,3,192.0.2.1
dhcp-option=lan2,3,172.25.0.1

# set DNS servers
dhcp-option=lan1,option:dns-server,192.0.2.2
dhcp-option=lan1,option:domain-search,dmz.gsx,intranet.gsx
# options can be discovered by running "dnsmasq --help dhcp"
dhcp-option=lan2,6,172.25.0.1
dhcp-option=lan2,119,intranet.gsx,dmz.gsx

# known hosts: static IP & name
#dhcp-host=02:03:04:05:06:07,NOM,IP
# caveat: virtual machines may change MAC address

#dhcp-ignore=tag:!known	# == deny unkown-clients

# Asignar IP fija a vm1 en la DMZ
dhcp-host=a2:b3:c4:d5:e6:f7,192.0.2.2
# Asignar IP fija a vm3 en la DMZ
dhcp-host=86:df:50:46:29:c3,192.0.2.254

# Opciones DHCP para los clientes
dhcp-option=lan1,option:domain-name,dmz.gsx
dhcp-option=lan2,option:domain-name,intranet.gsx

EOF

if ! grep 'DNSMASQ_OPTS=" -p0"' /etc/default/dnsmasq; then
	#Editar /etc/default/dnsmasq para desactivar el puerto 53
	echo 'DNSMASQ_OPTS=" -p0"' >> /etc/default/dnsmasq
fi

systemctl restart dnsmasq
#Verificar logs
#journalctl -u dnsmasq -e | cat | tail -10

MASQ3="DROP       tcp  -- !192.0.2.2            anywhere             tcp dpt:domain"
# Verificar si las reglas ya están presentes
if ! iptables -L | grep -q -E "$MASQ3"; then
    echo "Añadiendo regla FORWARD DNS"
    iptables -A FORWARD -o eth0 ! -s 192.0.2.2 -p tcp --dport 53 -j DROP
else
    echo "La regla FORWARD DNS  ya está activa."
fi


cat << EOF > /etc/dhcp/dhclient.conf
# Configuration file for /sbin/dhclient.
#
# This is a sample configuration file for dhclient. See dhclient.conf's
#       man page for more information about the syntax of this file
#       and a more comprehensive list of the parameters understood by
#       dhclient.
#
# Normally, if the DHCP server provides reasonable information and does
#       not leave anything out (like the domain name, for example), then
#       few changes must be made to this file, if any.
#

option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;

send host-name = gethostname();
request subnet-mask, broadcast-address, time-offset, routers,
        domain-name, domain-name-servers, domain-search, host-name,
        dhcp6.name-servers, dhcp6.domain-search, dhcp6.fqdn, dhcp6.sntp-servers,
        netbios-name-servers, netbios-scope, interface-mtu,
        rfc3442-classless-static-routes, ntp-servers;

#send dhcp-client-identifier 1:0:a0:24:ab:fb:9c;
#send dhcp-lease-time 3600;
supersede domain-name "fugue.com home.vix.com";
prepend domain-name-servers 127.0.0.1;
#require subnet-mask, domain-name-servers;
#timeout 60;
#retry 60;
#reboot 10;
#select-timeout 5;
#initial-interval 2;
#script "/sbin/dhclient-script";
#media "-link0 -link1 -link2", "link0 link1";
#reject 192.33.137.209;

#alias {
#  interface "eth0";
#  fixed-address 192.5.5.213;
#  option subnet-mask 255.255.255.255;
#}

#lease {
#  interface "eth0";
#  fixed-address 192.33.137.200;
#  medium "link0 link1";
#  option host-name "andare.swiftmedia.com";
#  option subnet-mask 255.255.255.0;
#  option broadcast-address 192.33.137.255;
#  option routers 192.33.137.250;
#  option domain-name-servers 127.0.0.1;
#  renew 2 2000/1/12 00:00:01;
#  rebind 2 2000/1/12 00:00:01;
#  expire 2 2000/1/12 00:00:01;
#}
EOF
ifdown eth0 > /dev/null
ifup eth0 > /dev/null


cat << EOF > /etc/resolv.conf
search intranet.gsx dmz.gsx
nameserver 192.0.2.2
EOF

#!/bin/bash

# Configuración de IPs
IPexternaVM0=$(ip route get 1 | awk '{print $7}' | head -n 1)
IPdestino="192.0.2.254"

# Verificar si la regla ya existe
if ! iptables -t nat -L PREROUTING -n | grep -q "DNAT.*$IPexternaVM0.*to:$IPdestino"; then
    echo "[+] Añadiendo regla DNAT: $IPexternaVM0 -> $IPdestino"
    iptables -t nat -A PREROUTING -d "$IPexternaVM0" -j DNAT --to-destination "$IPdestino"
else
    echo "[+] La regla DNAT ya existe:"
    iptables -t nat -L PREROUTING -n | grep "DNAT.*$IPexternaVM0"
fi

# Mostrar resumen de reglas
echo -e "\n[+] Reglas NAT actuales:"
iptables -t nat -L PREROUTING -n
