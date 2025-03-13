#!/bin/sh

# Descripció:
# Crear la infraestructura de xarxa al host/AMFITRIÓ
# Crear els bridges i connectant-hi les vNICs i la NIC de Internet

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 2.0

echo "Exec: $0\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" >/dev/null 2>&1

fitxer=$relpath/adquireix_nic.sh
[ ! -x $fitxer ] && echoError "Falta el fitxer (executable) $fitxer" && exit 1

mkdir -p /etc/network/interfaces.d

echo "Preparant els ponts a interfaces.d ..."
echo "
auto $PONT0
iface $PONT0 inet manual
brige_ports $outINTF
bridge_stp off
bridge_fd 0
bridge_maxwait 0
" > /etc/network/interfaces.d/hostBridge0.conf

n=1
for pont in $PONTS ; do
	[ $pont = $PONT0 ] && continue
	cat <<- FINAL > /etc/network/interfaces.d/hostBridge$n.conf
	auto $pont
	iface $pont inet manual
	bridge_fd 0
	bridge_maxwait 0
	bridge_stp off
FINAL
	n=$(($n+1))
done

fet=$(ls -C1 /etc/network/interfaces.d/hostBridge?.conf | wc -l)
nbr=$(echo $PONTS | wc -w)
falten=$(($nbr - $fet))
[ $falten -gt 0 ] && \
echoError "alguna ($falten) configuració de pont no s'ha pogut fer!" && exit 1

nomPonts=$(echo $PONT0 | tr -d [0-9])
fet=$(ip link | grep "${nomPonts}[0-9]:" | wc -l)
if [ $fet -eq $nbr ]; then
	echo "Els ponts virtuals ja estan creats."
else
	echo "Fent les NICs els ponts: $PONTS"
	for br in $PONTS
	do
		ip link show $br >/dev/null 2>&1
		[ $? -eq 0 ] && continue	# si creat el salto

		echo "nou pont: $br"
		ip link add $br type bridge
		ip link set dev $br up
		# desactivar IPv6 per a facilitar els pings multicast reals
		sysctl -q -w net.ipv6.conf.${br}.disable_ipv6=1

		# comprovar que tot ha anat bé:
		ip link show $br >/dev/null 2>&1
		[ $? -eq 1 ] && echoError "el pont $br no s'ha creat !!\n"
	done
fi

fet=$(ip link | grep "${nomPonts}[0-9]:" | wc -l)
[ $fet -ne $nbr ] && echoError "No s'han creat tots els ponts virtuals necessaris"

# punxar outINTF al pont
# sense IP però UP per a poder tenir Internet
ip link show $PONT0 >/dev/null 2>&1
[ $? -ne 0 ] && echoError "el pont principal $PONT0 no s'ha creat !!\n" && exit 1

intf=$(ip -d link | grep "\<master\> $PONT0" | head -1 | sed "s/[0-9]\+: \(\w*\).*/\1/")
if [ ${#intf} -gt 0 ]; then
	echo "la interfície principal ($intf) ja esta punxada al pont $PONT0." 
else
	IP=$(ip -4 address show $outINTF 2>/dev/null | grep inet | tr -s ' ' | cut -f3 -d' ' | cut -f1 -d/)
	$relpath/adquireix_nic.sh
	[ $? -ne 0 ] && echoError "no puc gestionar la $outINTF !!\n" && exit 1

	updown=$(grep -c "^iface *$outINTF *inet *dhcp" /etc/network/interfaces)
	if [ $updown -gt 0 ]; then
		echoAvis "desconnectant temporalment $outINTF"
		ifdown --force $outINTF
		# comentar la línia de config de la intf principal
		sed -i -e "s/^[^#]*iface $outINTF.*dhcp/iface $outINTF inet manual/" /etc/network/interfaces
		# la poso en manual per a evitar que salti un dhclient
	else
		ip link set dev $outINTF down
	fi
	# tot i estar down poden quedar restes, p.e. a la routing table
	ip address flush dev $outINTF

	echo "connectant $outINTF a un port del $PONT0"
	ip link set dev $outINTF master $PONT0
	ip link set dev $outINTF up
	#ip -d link show enp0s3 | grep --color "master [^ ]*"
fi

# als Labs cal adaptar la MAC pel DHCP: copiar la de la NIC principal
macINTF=$(ip link show $outINTF| grep "ether" | tr -s ' ' | cut -f3 -d' ')
OUI=$(echo $macINTF | grep -o "^\([0-9a-fA-F]\{2\}:\)\{3\}")
#if [ $outINTF != $PONT0 -a "$OUI" = "00:10:21:" ]; then
if [ "$OUI" = "00:10:21:" ]; then
	ip link set $PONT0 down
	ip link set $PONT0 address $macINTF
	ip link set $PONT0 up
fi

if [ $outINTF != $PONT0 -o -z $outIP ]; then
	ifdown --force $PONT0
	# no es podia posar en dhcp abans perquè no estava connectat a la outINTF
	sed -i "s/\(iface $PONT0 inet\) manual/\1 dhcp/" /etc/network/interfaces.d/hostBridge0.conf
	# la IP la tindrà el pont,adquirida per DHCP via la intf física principal
	ifup $PONT0 2>&1 | grep "[A-Z]\{5,\}"
else
	echo "El pont $outINTF ja està connectat a Internet ($outIP)"
fi

# i si ha fallat el dhclient per PONT0 ?
. "$definicions"
[ -z $outIP ] && exit 1
echo
exit 0
