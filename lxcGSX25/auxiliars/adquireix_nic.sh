#!/bin/sh

# Descripció:
# 	Pren el control de la interfície de sortida.
# 	Evita interferències amb els gestors locals de xarxa.
#	Mentre durin les pràctiques usarem ifupdown.

# Requisits: ifupdown, iproute2, systemd

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.5

echo "Exec: $0\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

LANG=C	# output anglès: busco unmanaged

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" >/dev/null 2>&1

espont=$(ip -d link show $outINTF | grep -c "\<bridge\>")
if [ $espont -ne 0 ]; then
	INTF=$(ip -d link  | grep "\<master\>" | head -1 | sed "s/[0-9]\+: \(\w*\).*/\1/")
	echoError "no es pot usar amb $outINTF, hauria de ser $INTF"
	exit 1
fi

# trobar qui gestiona la interfície:
gestio="Ningú"

systemctl --no-pager status NetworkManager >/dev/null 2>&1
if [ $? -eq 0 ]; then
	si=$(nmcli dev | grep -v unmanaged | grep -v external | grep -c $outINTF)
	if [ $si -gt 0 ]; then
		gestio="NM"
		echo "Prenent la gestió de $outINTF al NetworkManager"
		configNM="/etc/NetworkManager/NetworkManager.conf"

		# evitar que el NM gestioni les definides a interfaces
		ja=$(grep -n "\[ifupdown\]" $configNM | cut -f1 -d:)
		ja=${ja:-0}
		[ $ja -eq 0 ] && echo "\n[ifupdown]" >> $configNM

		sed -i "s/^managed=true/#managed=true/" $configNM
		ja=$(grep -c "managed=false" $configNM)
		[ $ja -eq 0 ] && echo "managed=false" >> $configNM

		ja=$(grep -c "\[keyfile\]" $configNM)
		if [ $ja -eq 0 ]; then
			echo "\n[keyfile]" >> $configNM
		fi
		ja=$(grep -c "^unmanaged.*$outINF" $configNM)
		if [ $ja -eq 0 ]; then
			nlinia=$(grep -n "\[keyfile\]" $configNM | cut -f1 -d:)
			sed -i "${nlinia}a unmanaged-devices=interface-name:$outINTF" $configNM
		fi
		systemctl restart NetworkManager
		# per si de cas:
		nmcli dev set $outINTF managed no
	fi
fi
# prioritat al NM
systemctl --no-pager status systemd-networkd >/dev/null 2>&1
if [ $? -ne 0 -a $gestio = "Ningú" ]; then 
	si=$(networkctl list 2>/dev/null | grep -v unmanaged | grep -c $outINTF)
	if [ $si -gt 0 ]; then
		echoAvis "La gestió la fa systemd-networkd"
		echo "i és complicat prendre-li una única interfície"
		echoError "Avís: Desactivo completament el servei"
		systemctl stop systemd-networkd
		systemctl disable systemd-networkd
	fi
fi

# algunes distros no inclouen el .d i ifupdown no els llegeix
activat=$(grep -ic "source /etc/network/interfaces.d" /etc/network/interfaces)
if [ $activat -eq 0 ]; then
	echo "source /etc/network/interfaces.d/*" >>/etc/network/interfaces
fi

# control de la xarxa virtual amb IFUPDOWN
# però la outINTF encara hauria de tenir IP i connexió a Internet

echo "Fi de $0\n"
exit 0
