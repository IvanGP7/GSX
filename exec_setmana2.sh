#!/bin/bash

test_monitoritzar_service(){
    echo "**Clean all the posibles files before testing.**"
    ./uninstall_monitoritza.sh
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


test_monitoritzar_service