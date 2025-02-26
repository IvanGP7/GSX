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

test_nice(){
    nice -n 19 ./copia_seguretat /etc /lib /sys /usr /var
}
#test_monitoritzar_log

test_nice