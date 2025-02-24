#!/bin/bash

test_monitoritzar_service(){
    echo "Clean all the posibles files before testing."
    ./uninstall_monitoritza.sh
    echo "Execute and prepare all service set up with all param."
    ./install_monitoritza.sh
}