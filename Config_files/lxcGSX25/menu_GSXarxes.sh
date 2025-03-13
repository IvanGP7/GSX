#!/bin/sh

# Descripció:
#	Menú principal del les pràctiques de xarxes de GSX
#	Quan alguna cosa va malament acaba per a que es pugui veure la sortida.
#
# Requisits: whiptail, LANG="ca_ES.UTF-8"

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.8

[ $(id -u) -ne 0 ] && echo "$0: Has de ser root" && exit 1

cwd=$PWD
path=$(realpath "$0")
dir=$(dirname "$path")
[ ! -d "$dir"/auxiliars ] && echo "No existeix $dir/auxiliars" && exit 1
cd "$dir"
. auxiliars/definicions.sh >/dev/null 2>&1

# instal·lar els paquets necessaris per aquest script:
dpkg-query --status whiptail >/dev/null 2>&1
[ $? -ne 0 ] && apt-get install -y whiptail 2>/dev/null

dimensions="20 0 0"

accions() {
	case $opcio in
		"Requisits")	auxiliars/comprova_requisits.sh
				return $?
				;;
		"Crear")
				auxiliars/prepara_requisits.sh
				[ $? -ne 0 ] && return 1
				auxiliars/crea_ponts_virtuals.sh
				[ $? -ne 0 ] && return 1
				read -p "	... prem [ENTER] ..." dummy
				auxiliars/crea_contenidors.sh
				[ $? -ne 0 ] && return 1
				auxiliars/gsxnet_guests.sh
				[ $? -eq 0 ] && opcio="Start" && return 0 || return 1
				;;
		"Start")
				auxiliars/engega_contenidors_lxc.sh
				[ $? -eq 0 ] && opcio="Stop" && return 0 || return 1
				;;
		"Stop")
				auxiliars/atura_contenidors_lxc.sh 
				[ $? -eq 0 ] && opcio="Start" && return 0 || return 1
				;;
		"Destruir")
				auxiliars/elimina_contenidors.sh
				[ $? -ne 0 ] && return 1
				auxiliars/elimina_ponts.sh
				[ $? -ne 0 ] && return 1
				auxiliars/comprova_internet.sh
				[ $? -eq 0 ] && opcio="Crear" && return 0 || return 1
				;;
		"Entorn")	auxiliars/comprova_entorn.sh $1
				[ $? -ne 0 ] && opcio="Crear" || opcio="Start"
				return 0
				;;
		"Connexió")	auxiliars/comprova_internet.sh
				return $?
				;;
		"Real")
				auxiliars/elimina_ponts.sh
				[ $? -ne 0 ] && return 1
				read -p "	... prem [ENTER] ..." dummy
				auxiliars/comprova_internet.sh
				[ $? -eq 0 ] && opcio="Virtual" && return 0 || return 1
				;;
		"Virtual")
				auxiliars/crea_ponts_virtuals.sh
				[ $? -ne 0 ] && return 1
				auxiliars/gsxnet_guests.sh
				[ $? -ne 0 ] && return 1
				read -p "	... prem [ENTER] ..." dummy
				auxiliars/comprova_internet.sh
				if [ $? -eq 0 ]; then
					opcio="Start" 
				else
					opcio="Real" 
				fi
				;;
		"Renovar")	auxiliars/renova_virtual.sh
				if [ $? -eq 0 ]; then
					opcio="Start"
				else
					opcio="Real"
				fi
				;;
		*)	opcio="Cap"
	esac
	return 0
}

acabar=0

dedueix_opcio() {
	ncontenidors=$(lxc-ls | sed "s/$NODEBASE//" | wc -w)
	maxContenidors=$(echo $NODES | wc -w)
	[ $ncontenidors -lt $maxContenidors ] && accio="Crear" && return

	nomPonts=$(echo $PONT0 | tr -d [0-9])
	nponts=$(ip link | grep -c "$nomPonts.:")
	maxPonts=$(echo $PONTS | wc -w)
	[ $nponts -lt $maxPonts ] && opcio="Virtual" && return

	ping -c1 -W1 8.8.8.8 >/tmp/sortida.txt 2>&1
	[ $? -ne 0 ] && opcio="Renovar" && return

	tincRouter=$(lxc-ls $ROUTER | grep -c $ROUTER)
	if [ $tincRouter -eq 1 ]; then 
		executant=$(lxc-ls --running | grep -c $ROUTER)
		if [ $executant -eq 1 ]; then
			opcio="Stop"
		else
			opcio="Start"
		fi
	else
		opcio="Crear"
	fi
}

dedueix_opcio
while [ $acabar -eq 0 ]
do
	opcio=$(whiptail --title "Pràctiques de xarxes de GSX v2" \
		--menu "Tria una acció": $dimensions \
		"Crear" "Crear els contenidors i la xarxa virtual" \
		"Start" "Executar els contenidors" \
		"Stop" "Aturar els contenidors" \
		"Destruir" "Tancar, eliminar i restaurar" \
		"	" "" \
		"Transitoris:" "	" \
		"Real" "Eliminar la xarxa virtual (temporalment)" \
		"Virtual" "Tornar a crear la xarxa virtual" \
		"Renovar" "Obtenir config per DHCP a la xarxa virtual" \
		"	" "" \
		"Informatius:" "	" \
		"Connexió" "Comprovar la connexió a Internet" \
		"Entorn" "Comprovar l'entorn virtual" \
		"Requisits" "Comprovar els requisits" \
		--default-item=$opcio \
		--cancel-button "Sortir" \
		3>&1 1>&2 2>&3)
	[ ${#opcio} -eq 0 ] && break
	[ ${#opcio} -eq 1 ] && dedueix_opcio && continue	# línies separadores

	accions $opcio
	acabar=$?
	if [ $acabar -eq 0 -a $opcio != "Cap" ]; then
		read -p "	... prem [ENTER] ..." dummy
	fi
	if [ $opcio = "Cap" ]; then
		dedueix_opcio
	fi
done

cd "$cwd"
