#!/bin/sh

# Descripció:
# Per a fer echo vermell dels errors i blau dels avisos
# Requisits: coreutils

# s'ha d'incloure als altres scripts amb:
#. ./echo_colors.sh

# Us:
# echoError missatge
# echoAvis missatge

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.3

RED='\033[0;31m'
LRED='\033[1;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
YLLW='\033[1;33m'
NOC='\033[0m' # No Color

# aquests després del color
BOLD=$(tput bold)
NORM=$(tput sgr0)

echoError() {
# parametre: [header:] missatge
	missatge=$@
	header=$(echo $1 | grep -c "^[^ :]\+:") 
	if [ $header -gt 0 ]; then
		header=$(echo $missatge | grep -o "^[^ :]\+:") 
		missatge=$(echo $missatge | cut -f2 -d:)
	else
		header="Error:"
	fi
	printf "${LRED}${BOLD}$header $missatge $NORM\n\n"
}

echoAvis() {
# parametre: [header:] missatge
	missatge=$@
	header=$(echo $1 | grep -c ':')
	if [ $header -gt 0 ]; then
		header=$(echo $missatge | cut -f1 -d:)
		missatge=$(echo $missatge | cut -f2 -d:)
	else
		header="Avís"
	fi
	printf "${YLLW}${BOLD}$header: $missatge $NORM\n"
}
