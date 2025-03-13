#!/bin/sh

# Descripció:
# Crear els contenidors i configurar la xarxa.
# Requereix: lxc, debootstrap (si cal els instal.la)

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 2.4

echo "Exec: $0\n"
[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

[ $# -eq 1 ] && interactiu=0 || interactiu=1

path=$(dirname "$(realpath "$0")")
definicions=$(find "$path" -name "definicions.sh" | head -1)
[ -z "$definicions" ] && echo "Falta el fitxer: definicions.sh" && exit 1
[ ! -f "$definicions" ] && echo "Falta +x a: definicions.sh" && exit 1
. "$definicions" 2>/dev/null

# comprovar els requisits (els paquets ja es miren a prepara_requisits.sh)
dpkg-query --status lxc >/dev/null 2>&1
if [ $? -ne 0 ]; then
	apt-get update
	apt-get install -y lxc debootstrap
	[ $? -ne 0 ] && echo "Error en el install. Acabo." && exit 1
fi

manca_espai() {
	echoError "Sembla que $espai de disc lliure no es sufucient per a fer les pràctiques."
	echo "Podria ser que funcionés a partir de 3GB."
	echo "Prova d'editar $0 i canviar el límit requerit."
	exit 1
}

n=$(echo $NODES | wc -w)
requereix=$(($n+1))	# 1G per node segurament serà suficient
espai=$(df -h  | grep "/$" | tr -s ' ' | cut -f 4 -d' ')
units=$(echo $espai | tr -d [0-9])
mida=$(echo $espai | tr -d [A-Z] | tr [.] [,] | cut -f1 -d,)

[ $units = 'K' -o $units = 'M' ] && manca_espai
[ $units = 'G' -a $mida -lt $requereix ] && manca_espai

# vital: comprovar el DNS
host -4 -W2 google.com >/dev/null 2>&1
[ $? -ne 0 ] && echoError "El DNS no funciona: no podrem instal.lar res." && exit 1

# OPCIONS del debootstrap: 
paquets="bind9-host,bind9utils,curl,dhcpdump,dnsutils,gawk,iptables,iputils-ping,iputils-tracepath,less,libc-bin,links,man-db,nano,netcat-traditional,nmap,openssh-client,patch,perl-base,procps,sudo,tcpdump,telnet,traceroute,tree,vim,wget,snmp,snmpd,snmp-mibs-downloader"

hw=$(uname -m)
if [ $hw = "x86_64" ]; then
	hw="amd64"
elif [ $hw = "aarch64" ]; then
	hw="arm64"
else
	echo "Architectura de la CPU $hw no suportada."
	hw="amd64"
	echo "Provo sort am $hw ..."
	[ $interactiu -eq 1 ] && read -p "	... prem [ENTER] per a seguir ..." dummy
fi

opcions="--arch $hw --enable-non-free --packages=$paquets"

tinc=$(gpg --list-keys | grep -c $release)
if [ $tinc -eq 0 ]; then
	wget "https://ftp-master.debian.org/keys/release-$version.asc" -O /tmp/release-$version.asc
	gpg --import /tmp/release-$version.asc 
fi
tinc=$(gpg --list-keys | grep -c $release)

if [ $tinc -eq 0 ]; then
	echoAvis "No tenim la clau GPG per a validar els paquets."
fi

echo
echo "Creo els contenidors de les VMs: "

existeix=$(lxc-ls | grep -c $NODEBASE)
if [ $existeix -eq 0 ]; then
	echo "Creant el node: '$NODEBASE' ..."
	lxc-create --logpriority=INFO --template debian --name $NODEBASE -- --release $release $opcions

	# ha anat bé ?
	existeix=$(lxc-ls $NODEBASE | grep -c $NODEBASE)
	[ $existeix -eq 0 ] && echoError "no s'ha creat el node: '$NODEBASE'" && exit 1
	sed -i "s/# *umask.*/umask 077/" $LXCPATH/$NODEBASE/rootfs/root/.bashrc
	# posar el password de root
	echo -n "milax\nmilax" | lxc-execute $NODEBASE passwd
	# permetre ssh al root amb password
	echo "PermitRootLogin yes" >> $LXCPATH/$NODEBASE/rootfs/etc/ssh/sshd_config
fi

for node in $NODES
do
	existeix=$(lxc-ls $node | grep -c $node)
	if [ $existeix -eq 0 ]; then
		echo "Clonant el contenidor: '$node ...'"
		lxc-copy -o /tmp/debug_clona_lxc.txt $NODEBASE --newname $node
		existeix=$(lxc-ls $node | grep -c $node)
		if [ $existeix -eq 0 ]; then
			echoError "no s'ha creat $node"
			echo "S'està executant el $NODEBASE llavors convé aturar-lo."
			lxc-ls --fancy 
			exit 1
		fi
		# el nom del contenidor canvia, però el del etc NO !
		echo $node | tee $LXCPATH/$node/rootfs/etc/hostname
		sed -i "s/# *umask.*/umask 077/" $LXCPATH/$node/rootfs/root/.bashrc
	else
		echo "Ja existeix el node: '$node'"
	fi
done

exit 0
