#!/bin/bash

test_monitoritzar_service_systemd(){
    echo "***************"
    echo "*  Systemctl  *"
    echo "***************"

    echo "**Clean all the posibles files before testing.**"
    ./uninstall_monitoritza.sh  2>/dev/null
    sleep 1

    echo "**Execute and prepare all service set up with all param.**"
    ./install_monitoritza.sh

    #
    # SI QUEREMOS CAMBIAR LAS VARIABLES DE SERVICIOS A REVISAR LOS ERRORES HAY QUE MODIFICAR EL ARCHIVO 'services'
    # QUE CONTIENE UNA VARIABLE QUE USA EL SCRIPT 'monitoritzar_logs.sh' CON LOS SERVICIOS A REVISAR ERRORES.
    #
    sleep 1
    echo "**Check if exist the result in monitoritzar_logs.log**"
    cat /var/log/monitoritzar_logs.log | tail -50

    echo "**Remove all service set up**"
    ./uninstall_monitoritza.sh
}

test_monitoritzar_service_sysV(){
    echo "**************"
    echo "*  System V  *"
    echo "**************"

    echo "**Execute and prepare all service set up with all param.**"
    ./install_sysV.sh

    #
    # SI QUEREMOS CAMBIAR LAS VARIABLES DE SERVICIOS A REVISAR LOS ERRORES HAY QUE MODIFICAR EL ARCHIVO 'services'
    # QUE CONTIENE UNA VARIABLE QUE USA EL SCRIPT 'monitoritzar_logs.sh' CON LOS SERVICIOS A REVISAR ERRORES.
    #
    sleep 1
    echo "**Check if exist the result in monitoritzar_logs.log**"
    cat /var/log/monitoritzar_logs.log | tail -50

    echo "**Remove all service set up**"
    ./uninstall_sysV.sh
}

test_monitoritzar_service_cron() {
    echo "**************"
    echo "*    Cron    *"
    echo "**************"

    echo "**Execute and prepare all service set up with all param.**"
    ./install_cron.sh


}

test_monitoritzar_service_systemd() {
    echo "**************"
    echo "*  Systemd   *"
    echo "**************"

    echo "**Execute and prepare all service set up with all param.**"
    ./install_timer.sh
}

test_cron_timer(){

    test_monitoritzar_service_cron

    test_monitoritzar_service_systemd   

    ./copia_seguretat.sh

    echo "**Remove all service set up**"
    ./uninstall_cron.sh
    ./uninstall_timer.sh
}

test_monitoritzar_service_systemd

test_monitoritzar_service_sysV

test_cron_timer