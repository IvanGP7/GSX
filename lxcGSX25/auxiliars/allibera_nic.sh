#!/bin/sh

# Descripció:
# 	Retorna el control de la interfície de sortida.
#	El pont virtual principal quedarà desconnectat de Internet
#	però els contenidors podran comunicar-se entre ells.
# Aixeca la interfície principal.

# Requisits: ifupdown, iproute2, systemd
# Abans s'hauria fet : adquireix_nics

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.7

echo "Exec: $0\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

LANG=C	# output anglès: busco unmanaged

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" >/dev/null 2>&1

espont=$(ip -d link show $outINTF | grep -c "\<bridge\>")
if [ $espont -eq 1 ]; then
	echoAvis "La interfície de sortida és $outINTF i no hauria de ser un pont"
	exit 1
fi

INTF=$(ip -d link  | grep "\<master\>" | head -1 | sed "s/[0-9]\+: \(\w*\).*/\1/")
if [ ${#intf} -gt 0 ]; then
	echo "desconnecto la NIC de sortida del $PONT0"
	ip link set dev $INTF nomaster
	ip link set dev $INTF down
else
	INTF=$outINTF
fi
#estat=$(ip link show $INTF | grep -o "state *\w*" | cut -f2 -d' ')
teip=$(ip -4 add show $INTF | grep -o "inet *[0-9\.]\+" | cut -f2 -d' ' | wc -c)

# trobar qui gestionava la interfície:
gestio="Ningú"
# 1ra prioritat al IFUPDOWN per dhcp o estàtica
updown=$(grep -c "^iface *$INTF *inet *\(manual\|static\)" /etc/network/interfaces)
# i si estigués a /etc/network/interfaces.d/ ?
if [ $updown -gt 0 ]; then
	gestio="IFUPDOWN"
	# des-comentar la línia de config de la intf principal
	sed -i -e "s/^[^#]*iface $INTF.*manual/iface $INTF inet dhcp/" /etc/network/interfaces
	[ $teip -eq 0 ] && ifup --force $INTF
else
	updown=$(grep -c "^iface *$INTF *inet *static" /etc/network/interfaces)
	if [ $updown -gt 0 ]; then 
		gestio="IFUPDOWN"
		[ $teip -eq 0 ] && ifup --force $INTF && sleep 3
	fi
fi

# 2n prioritat al NM
#systemctl --no-pager status NetworkManager >/dev/null 2>&1
dpkg-query --status network-manager >/dev/null 2>&1
if [ $? -eq 0 -a $gestio = "Ningú" ]; then 
	configNM="/etc/NetworkManager/NetworkManager.conf"

	ja=$(grep -c "#managed=true" $configNM)
	if [ $ja -gt 0 ]; then
		# Tornant-li les interfíces gestionades al NM
		sed -i "s/managed=false//" $configNM
		sed -i "s/^#managed=true/managed=true/" $configNM
	fi
	ja=$(grep -c "^unmanaged.*$INTF" $configNM)
	if [ $ja -ne 0 ]; then
		sed -i "s/unmanaged-devices=interface-name:$INTF//" $configNM
		nmcli dev set $INTF managed yes
	fi
	if [ $ja -ne 0 ]; then
		gestio="NM"
		systemctl restart NetworkManager
		nmcli dev connect $INTF
	fi
fi

if [ $gestio = "Ningú" ]; then 
	systemctl --no-pager status systemd-networkd >/dev/null 2>&1
	if [ $? -ne 0 ]; then 
		echo "Activo el servei systemd-networkd"
		systemctl restart systemd-resolved
		systemctl enable systemd-networkd
		systemctl start systemd-networkd
	fi
	networkctl up $INTF 2>/dev/null
	gestio="SD-ND"
fi

estat=$(ip link show $INTF 2>/dev/null | grep -o "state \w*" | cut -f2 -d' ')
if [ $estat != "UP" ]; then
	echoAvis "... esperant uns segons a que s'aixequi $INTF ..."
	sleep 3
fi
# control de la xarxa real al seu gestor

echo "Fi de $0: $INTF gestionada per $gestio\n"
exit 0
