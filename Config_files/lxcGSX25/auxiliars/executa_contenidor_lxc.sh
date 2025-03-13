#!/bin/sh

# Descripció:
# executa un dels contenidors de GSX passat per paràmetre
# Per errors consulta /tmp/debug_*.log

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.5

echo "Exec: $0 $*\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1
[ "$2" = "bg" ] && background=1 || background=0 # bg= no fa l'attach

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" >/dev/null 2>&1

params=$(echo $NODES | tr ' ' '|')
[ $# -eq 0 ] && echoAvis "Us: $0 $params" && exit 1

node=$1
existeix=$(lxc-ls $node | wc -l)
[ $existeix -ne 1 ] && echoError "el contenidor '$node' no existeix. Cal crear-lo" && exit 1

executant=$(lxc-ls --running $node | wc -l)
if [ $executant -eq 0 ]; then
	lxc-start -l trace -o /tmp/debug_$node.log $node
	echo "Fet. Logs a :/tmp/debug_$node.log"
fi

executant=$(lxc-ls --running $node | wc -l)
if [ $executant -eq 0 ]; then
	echoError "alguna cossa no va bé. El contenidor '$node' NO s'està executant"
	exit 1
else
	echo "OK: el contenidor '$node' s'està executant"
fi

[ $background -ne 0 ] && exit 0

ja=$(ps aux | grep -v grep | grep -c "lxc-attach $node")
if [ $ja -gt 0 ]; then
	echoAvis "Ja tens $ja terminals amb prompt a $node."
	read -p "Entra una s si vols tenir-ne un de nou : " seguir
	[ "$seguir" != "s" ] && echo "doncs no ho faig." && exit 0
fi

# establir el títol de la finestra per a una identificació fàcil
titol=$(echo $node | tr "a-z" "A-Z")
echo "\033]0;$titol\007"


lxc-attach $node login
echo

# reset terminal title
echo "\033]0;\007"
exit 0
