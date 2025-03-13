#!/bin/sh

# Descripció:
# Un cop creats i configurats els ponts al host
# connecta cada contenidor/guest/VM als ponts
# creant la infraestructura de xarxa.

# Requisits: ponts creats, adquirit control de nic, contenidors creats

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# versió: 1.20

echo "Exec: $0\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" >/dev/null 2>&1

fitxer=$relpath/comprova_entorn.sh
[ ! -x $fitxer ] && echoError "Falta el fitxer (executable) $fitxer." && exit 1

# comprovar que tot està a punt
$relpath/comprova_entorn.sh bg >/dev/null 2>&1
ret=$?
case $ret in
	0)
		n=$(ip -o link show $PONT0 | wc -l)
		# TODO: comprovar tota la topologia, no sols el PONT0
		if [ $n -ge 3 ]; then
			echo "Els guests/contenidors ja estan a la xarxa virtual"
			exit 0
		fi
		;;
	128) 
		;;
	*)	echoError "$0 falla per entorn virtual incorrecte ($ret)."
		exit 1
		;;
esac
nponts=$(echo $PONTS | wc -w)
falten=$nponts

neteja_config_vNICs() {
	# si ja existeix la config de GSX al contenidor $1 la elimina
	existeix=$(grep -c "# GSX" $LXCPATH/$1/config)
	if [ $existeix -ne 0 ]; then
		echo "ja existeix la config del contenidor: '$1': l'elimino"
		ini=$(grep -n "# GSX configured" $LXCPATH/$1/config | head -1 | cut -f1 -d:)
		fin=$(grep -n "# EOF GSX" $LXCPATH/$1/config | tail -1 | cut -f1 -d:)
		[ "x$fin" = "x" ] && fin=$(wc -l $LXCPATH/$1/config)
		sed -i "$ini,${fin}d" $LXCPATH/$1/config
	fi
}

# al Lab210 cal adaptar la MAC pel DHCP: 00:10:21:01:PC:10 -> 10.112.200.100+PC
macINTF=$(ip link show $outINTF| grep "ether" | tr -s ' ' | cut -f3 -d' ')
OUI=$(echo $macINTF | grep -o "^\([0-9a-fA-F]\{2\}:\)\{3\}")
if [ "$OUI" = "00:10:21:" ]; then
	# estem a un lab
	PC=$(echo $macINTF | cut -f5 -d:)
	macRouter="00:10:21:01:$PC:10"	# encara que no sigui el lab210 !
fi

# una pota del router va a la xarxa externa i les altres a les xarxes internes
connecta_router2ponts() {
	# el fitxer $LXCPATH/$ROUTER/config es crea en fer lxc-create
	[ ! -f $LXCPATH/$ROUTER/config ] && echoError "No hi ha el router !" && return

	neteja_config_vNICs $ROUTER

	if [ ! -z $PONT0 ]; then
		cat <<- FINAL >> $LXCPATH/$ROUTER/config
			# GSX configured
			lxc.init.cwd = /root
			lxc.net.0.type = veth
			lxc.net.0.veth.pair = eth_${ROUTER}_$nomPONT0
			lxc.net.0.flags = up
			lxc.net.0.link = $PONT0
			lxc.net.0.name = eth0
		FINAL
		[ ! -z $macRouter ] && echo lxc.net.0.hwaddr = $macRouter >> $LXCPATH/$ROUTER/config
	fi
	if [ ! -z $PONT1 ]; then
		n=$(ip -o link show $PONT1 2>/dev/null | wc -l)
		if [ $n -eq 1 ]; then
			cat <<- FINAL >> $LXCPATH/$ROUTER/config
				lxc.net.1.type = veth
				lxc.net.1.veth.pair = eth_${ROUTER}_$nomPONT1
				lxc.net.1.flags = up
				lxc.net.1.link = $PONT1
				lxc.net.1.name = eth1
			FINAL
		else
			PONT1=
		fi
	fi
	if [ ! -z $PONT2 ]; then
		n=$(ip -o link show $PONT2 2>/dev/null | wc -l)
		if [ $n -eq 1 ]; then
			cat <<- FINAL >> $LXCPATH/$ROUTER/config
				lxc.net.2.type = veth
				lxc.net.2.veth.pair = eth_${ROUTER}_$nomPONT2
				lxc.net.2.flags = up
				lxc.net.2.link = $PONT2
				lxc.net.2.name = eth2
			FINAL
		else
			PONT2=
		fi
	fi
	echo "# EOF GSX net config" >> $LXCPATH/$ROUTER/config

	fet=$(grep -c "GSX configured" $LXCPATH/$ROUTER/config)
	[ $fet -eq 0 ] && echoError "$ROUTER no he pogut configurar la xarxa del $ROUTER al host !" && exit 1
	echo "connectades les vNICs del contenidor $ROUTER"
	falten=$(($falten-1))
}

connecta_router2ponts

# per si havíem retornat a la xarxa real temporalment
executant=$(lxc-ls --running $ROUTER | wc -l)
if [ $executant -ne 0 ]; then
	[ ! -z $PONT0 ] && ip link set dev eth_${ROUTER}_$nomPONT0 master $PONT0
	[ ! -z $PONT1 ] && ip link set dev eth_${ROUTER}_$nomPONT1 master $PONT1
	[ ! -z $PONT2 ] && ip link set dev eth_${ROUTER}_$nomPONT2 master $PONT2
fi

connecta_vm2pont() {
# la resta de nodes sols una intf connectada a un pont
	node=$1
	pont=$2
	[ ! -f $LXCPATH/$node/config ] && echoError "No hi ha el contenidor $node!" && return

	neteja_config_vNICs $node

	cat <<- FINAL >> $LXCPATH/$node/config
		# GSX configured
		lxc.init.cwd = /root
		lxc.net.0.type = veth
		lxc.net.0.veth.pair = eth_$node
		lxc.net.0.flags = up
		lxc.net.0.link = $pont
		lxc.net.0.name = eth0
		# EOF GSX net config
	FINAL
	fet=$(grep -c "GSX configured" $LXCPATH/$node/config)
	[ $fet -eq 0 ] && echoError "No he pogut configurar la xarxa del $node al host !" && exit 1
	echo "connectades les vNICs del contenidor '$node'"
	falten=$(($falten-1))
}

n=0
for node in $NODES
do
	[ "$node" = "$ROUTER" ] && continue
	n=$(($n+1))

	vm=$(grep -o "^[ 	]*NODE$n=[^ ]\+" "$definicions" | cut -f2 -d=)
	br0=vm${n}PONT		# var indirceta
	eval br="\$$br0"	# indirecció amb sh
	#br=${!br0}			# " en bash
	if [ -z $br ]; then
		echoError "$0: no tenim el pont on connectar el contenidor: $node."
		echo "Cal revisar el fitxer definicions.sh"
		exit 1
	fi
	if [ ! -z $vm ]; then
		echo "connectant '$vm' a '$br'"
		connecta_vm2pont $vm $br
		executant=$(lxc-ls --running $vm | wc -l)
		[ $executant -ne 0 ] && ip link set dev eth_$node master $br
	else
		echoError "$0: falta el contenidor: $node !"
	fi
	[ "$node" = "vm1" ] && 
		sed -i "s/# EOF GSX.*/lxc.net.0.hwaddr = a2:b3:c4:d5:e6:f7\n&/" $LXCPATH/$node/config
done

[ $falten -eq $nponts ] && echo "Els contenidors ja estaven connectats als ponts."
#echo
#lxc-ls --fancy
#echo 
#lxc-info $ROUTER | grep "IP\|Link"
echo

exit 0

