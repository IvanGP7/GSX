#!/bin/sh

# Descripció:
# 	mostra la info de xarxa i prova pings i dns.

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.2

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" 2>/dev/null

echo "\nEstat actual:\n"
ip -4 -c address show $outINTF
echo

MAXdhclients=1
if [ $outINTF = $PONT0 ]; then
	intf=$(/usr/sbin/bridge link show | grep -v "@" | cut -f2 -d: | tr -d ' ')
	if [ ${#intf} -gt 0 ]; then
		outINTF=$intf
		MAXdhclients=0	# la IP l'ha de tenir el pont
	else
		echoAvis "L'amfitrió no te cap interfície al $PONT0"
	fi
fi

nclients=$(ps aux | grep -v grep | grep -c "dhclient.*$outINTF")
if [ $nclients -gt $MAXdhclients ]; then
	echoAvis "Hi ha massa dhclients per a la interfície $outINTF"
	ps aux | grep -v grep | grep --color "dhclient.*$outINTF"
fi
echo "Taula d'encaminament:"
ip -c route

echo "\nProvant pings cap a Internet..."
ping -c2 -W1 8.8.8.8 >/tmp/sortida.txt 2>&1
no=$?

if [ $no -ne 0 ]; then
	echoError "FATAL !! \nping retorna:"
	cat /tmp/sortida.txt 
else
	echoAvis "OK"
	tail -1 /tmp/sortida.txt

	echo "\nProvant la resolució de noms..."
	host -4 -W1 www.tinet.cat 1>/tmp/sortida.txt 2>&1
	no=$?
	if [ $no -ne 0 ]; then
		echoError "FALLA el DNS i retorna:"
		cat /tmp/sortida.txt
	else
		echoAvis "OK"
	fi
	tail -1 /tmp/sortida.txt
fi
rm /tmp/sortida.txt

echo
exit $no
