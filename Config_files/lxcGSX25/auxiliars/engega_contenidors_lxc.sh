#!/bin/sh

# Descripció:
# executa els contenidors virtual i obre els terminals corresponents
# Requereix: xarxa virtual creada.

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.5

[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1
[ "$1" = "bg" ] && background=1 || background=0

echo "Exec: $0\n"
path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" >/dev/null 2>&1

fitxer="$relpath/executa_contenidor_lxc.sh"
[ ! -x $fitxer ] && echoError "Falta el fitxer (executable) $fitxer" && exit 1

fitxer=$relpath/comprova_entorn.sh
[ ! -x $fitxer ] && echoError "Falta el fitxer (executable) $fitxer" && exit 1

$relpath/comprova_entorn.sh bg >/dev/null 2>&1
[ $? -ne 0 ] && echoError "No pots engegar els contenidors sense crear l'entorn virtual !" && exit 1

sense_term=1
if [ ! -x $DISPLAY ]; then
	# entorn gràfic: terminals a xterm o el de gnome
	# prefereixo gnome-terminal pel copy&paste
	sense_term=0
	term=$(which gnome-terminal)
	if [ ${#term} -ne 0 ]; then
		termcmd=gnome-terminal
		OpcionsTerm=""
	else
		term=$(which xterm)
		if [ ${#term} -ne 0 ]; then
			termcmd=xterm
			OpcionsTerm="-u8 -fa 'Monospace' -fs 14 -class UXTerm"
		else
			echoAvis "no trobo cap terminal. Sols fare echos de les commandes."
			sense_term=1
		fi
	fi
	# permetre al root usar els xterms al $DISPLAY de l'usuari 
	[ $sense_term -eq 0 ] && xhost +si:localuser:root >/dev/null
fi

comanda="$relpath/executa_contenidor_lxc.sh"

revNodes=$(echo $NODES | tr ' ' '\n' | tac | tr -s '\n' ' ') # en ordre invers (router on top)
for node in $revNodes
do
	if [ $sense_term -eq 1 -o $background -ne 0 ]; then 
		$comanda $node bg
	else # tenim xterms
		echo "\nObrint un terminal per a '$node'"
		if [ "$termcmd" = "xterm" ]; then
			xterm $OpcionsTerm -e $comanda $node &

		else
			gnome-terminal $OpcionsTerm >/dev/null -- $comanda $node
		fi
		sleep 1
		if [ $node = $ROUTER ]; then
			iprouter=$(lxc-info -Hi $ROUTER)
			[ ${#iprouter} -lt 7 ] && echoAvis "el $ROUTER no té IP!" || echo "IP del router: $iprouter"
		fi
	fi
done

# comprovar que els tenim executant-se
for node in $NODES
do
	running=$(lxc-ls --running | grep -c "\<$node\>")
	if [ $running -eq 0 ]; then
		echoError "El '$node' no està executant-se !"
	fi
done

queden=$(lxc-ls --running | wc -w)
if [ $queden -gt 0 ]; then
	echo "\nS'estan executant els següents contenidors:"
	lxc-ls --running
#	echoAvis "Recorda: sortir del terminal amb 'exit' no atura el contenidor!"
	exit 0
else
	echoError "No hi ha cap contenidor executant-se !"
	echo
	exit 1
fi
