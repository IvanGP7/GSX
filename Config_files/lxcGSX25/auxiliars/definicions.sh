#!/bin/sh

# Descripció:
# Definicions de constants per a usar en altres scripts
# també troba i defineix la sortida cap a Internet.
# Sortida per stderr (excepte si no hi ha Internet)

# s'ha d'incloure amb:
#. ./definicions.sh
# o bé a bash:
# source ./definicions.sh

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 2.7

# si cridat directament mostrar sortida
test "#$(basename $0)" = "#definicions.sh" && sortida=1 || sortida=0

LXCPATH="$HOME/.local/share/lxc"	# quan NO usem el root (mode unprivileged)
LXCPATH="/var/lib/lxc"			# quan usem el root
LXCPATH=$(lxc-config lxc.lxcpath)

release=bookworm
version=12

PONT0=lxcbr0
PONT1=lxcbr1
PONT2=lxcbr2
nomPONT0=EXT
nomPONT1=DMZ
nomPONT2=INT

NODEBASE=inicial
NODE0=vm0
ROUTER=$NODE0 # alias, per a tenir scripts més nets
NODE1=vm1
NODE2=vm2
NODE3=vm3

# connexions de VM no router/vm0 a ponts
vm1PONT=$PONT1
vm3PONT=$PONT1
vm2PONT=$PONT2

NODES="$NODE0 $NODE1 $NODE2 $NODE3" 
PONTS="$PONT0 $PONT1 $PONT2" 

# lloc relatiu on hi ha els scripts
# usualment al dir: auxiliars/
relpath=$(dirname $0)

# carregar funcions auxiliars comunes:
if [ -f $relpath/echo_colors.sh ]; then
	. $relpath/echo_colors.sh
else
	echoError() { echo "Error: $1"
	}
	echoAvis() { echo "Avís: $1"
	}
fi

# obtenir informació de la xarxa actual (ISP?)
connectat=$(ip route | grep -v linkdown | grep default | wc -l)
case $connectat in
	0)
		echoAvis "Falta el default gateway!" >&2
		echoAvis "Si cal edita aquest fitxer i configura manualment outINTF i outIP\n" >&2

		echo provo amb la primera interficie >&2
		outINTF=$(ip link | grep "^[0-9]\+:" | grep -v "lo:" | head -1 | cut -f2 -d: | tr -d ' ')
		outIP=""
		echoAvis "provarem amb outINTF=$outINTF amb gateway=$outIP\n" >&2
		;;
	1)
		outINTF=$(ip route | grep -v linkdown | grep default | grep -o "dev [^ ]\+" | cut -f2 -d' ')
		[ ${#outINTF} -eq 0 ] && echoError "no he detectat la interfície de sortida.\n" && exit 1

		outIP=$(ip route | grep -v linkdown | grep default | grep -o "via [0-9.]\{7,15\} dev $outINF" | cut -f2 -d' ')
		[ ${#outIP} -eq 0 ] && echoAvis "no he detectat la IP del default gateway.\n" && ip route | grep -v linkdown | grep default
		;;
	*)	# N'hi ha diversos : usar el que encamina
		echoAvis "Hi ha diversos default gateways:" >&2
		ip route | grep default >&2
		outINTF=$(ip route get 1.1.1.1 | grep -o "dev [^ ]\+" | cut -f2 -d' ')
		outIP=$(ip route get 1.1.1.1 | grep -o "via [0-9.]\{7,15\}" | cut -f2 -d' ')
		if [ ${#outIP} -eq 0 ]; then
			echoAvis "no he detectat la IP de sortida.\n" >&2
		else
			echoAvis Triat:
			ip route | grep default | grep --color "$outIP *dev *$outINTF" >&2
		fi
		;;
esac

eswifi=$(networkctl list $outINTF 2>/dev/null | grep -ic wlan)
if [ $eswifi -ne 0 ]; then
	echoError "la connexió a Internet no pot ser per WiFi!\n"
	outINTF=""
	outIP=""
else
	[ $sortida ] && echoAvis "definicions.sh: trobat outINTF=$outINTF amb gateway=$outIP\n"
	[ ${#outIP} -lt 8 ] && echo "No he trobat el default gateway: de moment no tens accés  a Internet !" >&2
fi
