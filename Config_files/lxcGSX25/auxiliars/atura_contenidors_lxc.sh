#!/bin/sh

# Descripció:
# atura els contenidor lxc de GSX passat per paràmetre
# Si no hi ha parametre atura tots els que s'estan executant

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# versió: 1.4

echo "Exec: $0 $*\n"
path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" >/dev/null 2>&1

[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

queden=$(lxc-ls --running | wc -w)
if [ $queden -eq 0 ]; then
	echo "No hi ha cap contenidor executant-se."
	exit 0
fi

if [ $# -eq 0 ]; then
	tria=$(echo $NODES | tr ' ' '\n' | tac | tr -s '\n' ' ') # en ordre invers
else
	triaNode=$(echo $NODES | grep -c "\<$1\>")
	if [ $triaNode -eq 1 ]; then
		tria=$1
	else
		echoError "paràmetre \"$1\" incorrecte!" && exit 1
	fi
fi

echo "Intentant aturar: $tria (pot tardar !!)"

aturats=0
n=0
for node in $tria
do
	existeix=$(lxc-ls $node | wc -l)
	[ $existeix -ne 1 ] && echoError "el contenidor '$node' no existeix. Cal crear-lo" && continue

	executant=$(lxc-ls --running $node | wc -l)
	if [ $executant -eq 1 ]; then
		n=$(($n+1))
		executant=$(ps aux | grep "attach $node" | grep -v grep | wc -l)
		atura='s'
		if [ $executant -gt 0 ]; then
			echo "\nAvís: hi ha $executant terminal/s attached.\n"
			read -p ">>> Entra 'n' per a NO aturar el $node [S,n] " atura
		fi
		if [ ${#atura} -eq 0 -o "$atura" != "n" ]; then
			lxc-stop 2>/dev/null $node

			executant=$(lxc-ls --running $node | wc -l)
			if [ $executant -eq 1 ]; then
				echoError "no he pogut aturar el node: $node"
			else
				echo "aturat: $node."
				aturats=$(($aturats+1))
			fi
		fi
	else
		echo "el contenidor '$node' NO s'estava executant"
	fi
done
if [ $n -ne $aturats ]; then
	echoAvis "\nn'he aturat: $aturats.\n"
else
	echo "\nn'he aturat: $aturats.\n"
fi
queden=$(lxc-ls --running | wc -w)
if [ $queden -gt 0 ]; then
	echo "\nEncara queden executant-se els següents contenidors:"
	lxc-ls --running
fi

echo
exit 0
