#!/bin/sh

# Descripció:
# 	Eliminar la infraestructura de xarxa  virtual

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 2.0

echo "Exec: $0\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" 2>/dev/null

fitxer=$relpath/allibera_nic.sh
[ ! -x $fitxer ] && echoError "Falta el fitxer $fitxer" && exit 1

echo "\nEliminant les NIC del del HOST: $PONTS...\n"

br=$PONT0
ip link show $br >/dev/null 2>&1
if [ $? -eq 0 ]; then
	# alliberar la IP del vpont principal
	ifdown --force $PONT0

	# outINTF ha canviat:
	. "$definicions" >/dev/null 2>&1

	# desconectar la NIC de sortida del vpont abans que l'eliminem:
	ip link set dev $outINTF nomaster
	ip link set dev $outINTF down

	ip link set dev $br down
	ip link del $br 

# XXX XXX XXX
	# paranoia: queden dhclients ?
	for pid in $(ps ax -o pid,cmd | grep "dhclient.*$br" | grep -v grep | cut -f1 -d' ')
	do
		pa -fp $pid
		echoError "$0: MATANT dhclient $pid !"
		kill -9 $pid
	done
else
	echoAvis "$br no existeix"
fi

for br in $PONTS
do
	[ $br = $PONT0 ] && continue
	ip link show $br >/dev/null 2>&1
	[ $? -eq 1 ] && echoAvis "$br no existeix" && continue

	ip link set dev $br down
	ip link del $br 
done

#echo "\nQueden ponts?"
nomPonts=$(echo $PONT0 | tr -d [0-9])
bridge -d link | grep "$nomPonts.:"

si=$(ls /etc/network/interfaces.d/hostBridge?.conf 2>/dev/null| wc -l)
if [ $si -gt 0 ]; then
	echo "\nEliminant les configs dels ponts del HOST a interfaces.d:\n"
	rm /etc/network/interfaces.d/hostBridge?.conf
fi

$relpath/allibera_nic.sh

echo
exit 0
