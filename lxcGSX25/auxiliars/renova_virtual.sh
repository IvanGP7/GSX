#!/bin/sh

# Descripció:
# 	Si cal renova la IP etc del pont virtual
# 	Util per canvi de lloc de treball (o d'ISP)

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.1

echo "Exec: $0\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

definicions=$(find . -name "definicions.sh")
[ ! -f "$definicions" ] && echo "Falta el fitxer definicions.sh" && exit 1
. "$definicions" 2>/dev/null

# comprovar si ja tenim els ponts creats
ip link show $PONT0 >/dev/null 2>&1
[ $? -ne 0 ] && echoAvis "No existeix el pont virtual $PONT0"

ping -c2 -W1 8.8.8.8 >/tmp/sortida.txt 2>&1
[ $? -eq 0 ] && echo "No faig res: Internet és accessible." && exit 0

ifdown --force $PONT0
sleep 1
ifup $PONT0 2>&1 | grep "[A-Z]\{5,\}"

ping -c2 one.one.one.one
exit $?
