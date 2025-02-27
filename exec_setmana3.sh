#!/bin/bash


test_monitoritzar_log(){
    STATUS=$(systemctl is-active acct)
    if [[ $STATUS == "active" ]]; then
        sudo systemctl stop acct
    fi

    STATUS2=$(systemctl is-active polkit)
    if [[ $STATUS2 == "inactive" ]]; then
        sudo systemctl start polkit
    fi

    ./monitoritzar_logs.sh polkit acct not-existent-service
}

#test_monitoritzar_log

#Test del nice
#time ./test_cpu.sh

#test comprovar paquet with SIGINT

# Ruta al script que quieres ejecutar en una nueva pestaña
SCRIPT_PATH="./comprovar_paquet.sh"

# Abrir una nueva pestaña en la terminal actual y ejecutar el script
gnome-terminal -- bash -c "$SCRIPT_PATH; sleep 5"
sleep 3
sudo kill -SIGINT $(pgrep comprovar_paqu)
sleep 1
echo "Test SIGINT finished"

