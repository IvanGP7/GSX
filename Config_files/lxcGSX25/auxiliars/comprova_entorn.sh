#!/bin/sh

# Descripció:
# comprova l'estat actual de la infraestructura de contenidors LXC
# retorna 0 si hi ha els ponts creats i configurats
# altres valors depen del que falli

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.5

clear
echo "Exec: $0\n"

[ "$1" = "bg" ] && interactiu=0 || interactiu=1

[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1
# necessari pel accés als contenidors

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions"

# comprovar els requisits (els paquets ja es miren a prepara_requisits)
dpkg-query --status lxc >/dev/null 2>&1
[ $? -ne 0 ] && echoError "NO hi ha el paquet lxc instal·lat !" && exit 1

errors=0
for node in $NODEBASE $NODES
do
	existeix=$(lxc-ls $node | grep -c $node)
	if [ $node = $NODEBASE ]; then
		if [ $existeix -eq 0 ]; then
			echoError "NO existeix el node: '$node'"
		fi
		continue
	fi
	if [ $existeix -gt 0 ]; then
		estat=$(lxc-ls --running $node | grep -c $node)
		[ $estat -gt 0 ] && estat="executant-se" || estat="aturat"
		echo "OK: existeix el node: '$node' [$estat]"
	else
		echoError "NO existeix el node: '$node'"
		errors=$(($errors | 64))
	fi
done

[ $interactiu -eq 1 ] && read -p "	... prem [ENTER] per a seguir ..." dummy
clear

# PART gsx_host

# comprovar si ja tenim els ponts creats
maxPonts=$(echo $PONTS | wc -w)
nponts=0
for br in $PONTS
do
	ip link show $br >/dev/null 2>&1
	[ $? -eq 0 ] && nponts=$(($nponts+1))
done
if [ $nponts -eq $maxPonts ]; then
	upPONT0=$(ip -4 address show $PONT0 | grep inet | wc -l)
	if [ $upPONT0 -eq 1 ]; then 
		echo "OK: tenim els ponts creats"
	fi
elif [ $nponts -ne 0 ]; then
	echoAvis "Els ponts que tenim son:"
	ip -c link show type bridge
else
	echoError "NO tenim cap dels ponts pels lxc"
	errors=$(($errors | 1))
fi

if [ $nponts -gt 0 ]; then
	nponts2=$(ls  -l /etc/network/interfaces.d/hostBridge* 2>/dev/null | wc -l)
	[ $nponts2 -ne $maxPonts ] && echoError "no hi ha prou ponts posats a interfaces.d ($nponts2 de $maxPonts)." || echo "OK: interfaces.d pels ponts"
	intf=$(bridge link show | grep -v "@" | cut -f2 -d: | tr -d ' ')
	if [ ${#intf} -gt 0 -a "x$intf" != "x$PONT0" ]; then
		echo "OK: $intf connectada a $PONT0"
	else
		echoAvis "L'amfitrió no te cap interfície al $PONT0"
		errors=$(($errors | 2))
	fi
else
	nponts2=0
fi

tenimND=$(systemctl status systemd-networkd 2>/dev/null | grep -ic running)
if [ $tenimND -gt 0 ]; then
	echoAvis "networkd present:"
	networkctl list 2>/dev/null
[ $interactiu -eq 1 ] && read -p "	... prem [ENTER] per a seguir ..." dummy
clear

fi
tenimNM=$(systemctl status NetworkManager 2>/dev/null | grep -ic running)
if [ $tenimNM -gt 0 ]; then
	echoAvis "NetworkManager present:"
	nmcli dev
[ $interactiu -eq 1 ] && read -p "	... prem [ENTER] per a seguir ..." dummy
clear

fi
if [ -f /etc/network/interfaces ]; then
	# suposo que sols hi ha un interfície física
	intf1=$(ip link | grep "^2: " | cut -f2 -d: | tr -d ' ')
	updown=$(grep "^[^#].*iface " /etc/network/interfaces)
	[ ${#updown} -ne 0 ] && echoAvis "Hi ha interficies definides a /etc/network/interfaces:\n$updown"
fi

# hi ha d'haver exactament un default gateway (o per enmp0s3 o per lxcbr0)
ip route | grep -v linkdown | grep --color default
#outINTF=$(ip ro get 1.1.1.1 2>/dev/null | grep -o "dev *[^ @]\+" | cut -f2 -d' ')
n=$(ip ro get 1.1.1.1 2>/dev/null | grep -c "via .* dev ")
case $n in
	0)	echoError "Fatal: no tenim cap default gateway !"
		errors=$(($errors | 4))
		;;
	1)	echo "OK: tenim un default gateway"
		;;
	*)	echoError "si la interfície principal té IP i el $PONT0 també tindrem problemes!"
esac
[ $interactiu -eq 1 ] && read -p "	... prem [ENTER] per a seguir ..." dummy
clear

# PART gsx_guests

for node in $NODES
do
	existeix=$(lxc-ls $node | grep -c $node)
	[ $existeix -eq 0 ] && continue

	existeix=$(grep -c "GSX" $LXCPATH/$node/config)
	if [ $existeix -eq 0 ]; then
		echoAvis "NO existeix la config-lxc GSX del contenidor: '$node'"
		errors=$(($errors | 128))
	else
		echo "OK: sembla que el lxc $node té la config GSX" 
	fi
done

#[ $nponts -eq $maxPonts -a $nponts2 -eq $maxPonts ] && exit 0
exit $errors
