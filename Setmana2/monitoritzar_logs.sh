#!/bin/bash

#
# check-services: systemctl list-units --type=service --state=running
# test-run: ./missatge_logs.sh accounts-daemon acpid cron dbus getty@tty1 lightdm lxc-monitord mrtg NetworkManager polkit rsyslog udinsk2 upower user@1000 virtualbox-guest-utils
#

source /home/GSX/services

for service in $SERVICES_TO_CHECK; do                                             # For each param:
    echo "CHECKING ERRORS from the SERVICE: $service"
    sudo journalctl -u "$service" -xe | while read -r linea; do     # Getting all the errors form the choosen service
        echo "[$service] $linea"                                    # If service are desabled or does not exist the output is gonna be: -- No entries --
    done
    echo ""
    echo "********************************"
    echo ""
done
