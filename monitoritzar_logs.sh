#!/bin/bash

#
# check-services: systemctl list-units --type=service --state=running
# test-run: ./missatge_logs.sh accounts-daemon acpid cron dbus getty@tty1 lightdm lxc-monitord mrtg NetworkManager polkit rsyslog udinsk2 upower user@1000 virtualbox-guest-utils
#

if [ $# == 0 ]; then                                                #Check we recive some param
    echo "You have to write some services as param"
    exit 1
fi

for service in "$@"; do                                             # For each param:

    STATUS=$(systemctl is-active "$service")
    if [[ $STATUS == "inactive" ]]; then  # El servicio no esta en estado running
        echo "Ejecutar Servicio inactivo"
        sudo systemctl start $service > /dev/null
        if [[ $? == 0 ]]; then  # El servicio existe
            sudo systemctl status $service | cat
            echo "Servicio inicializado correctamente"
        else
            echo "El servicio $service no existe"
            break
        fi
    else 
        echo "Servce $service Is Alrady runing"
    fi
    echo "CHECKING ERRORS from the SERVICE: $service"
    sudo journalctl -u "$service" -xe | while read -r linea; do     # Getting all the errors form the choosen service
        echo "[$service] $linea"                                    # If service are desabled or does not exist the output is gonna be: -- No entries --
    done
    
    echo ""
    echo "Controll about service"
    INFO_PROCESS=$(pgrep -a $service)
    if [[ -z $INFO_PROCESS ]]; then
        echo "ERROR: Service $service has NO process active"
    else
        echo "SUCCESS: $INFO_PROCESS"
    fi
    echo ""
    echo "********************************"
    echo ""
done