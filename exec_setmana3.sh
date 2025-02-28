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

test_SIGINT(){
    # Ruta al script que quieres ejecutar en una nueva pestaña
    SCRIPT_PATH="./comprovar_paquet.sh"

    # Abrir una nueva pestaña en la terminal actual y ejecutar el script
    gnome-terminal -- bash -c "$SCRIPT_PATH; sleep 3"
    sleep 3
    sudo kill -SIGINT $(pgrep comprovar_paqu)
    sleep 1
    echo "Test SIGINT finished"
}

test_SIGUSR1(){
    FS_DIR="/home/milax/fake_fs"

    echo "Creating a File System in $FS_DIR..."
    sudo mkdir -p "$FS_DIR"
    for i in {1..7}; do
        sudo dd if=/dev/urandom of="$FS_DIR/file_$i.bin" bs=100M count=1 status=none
    done
    echo "Filse System Created!"

    # Ruta al script que quieres ejecutar en una nueva pestaña
    SCRIPT_PATH="/home/GSX/copia_seguretat.sh $FS_DIR"

    # Abrir una nueva pestaña en la terminal actual y ejecutar el script
    gnome-terminal -- bash -c "$SCRIPT_PATH; sleep 4"
    echo "Esperando a que el proceso tar comience..."
    while true; do
        if pgrep -x "tar" > /dev/null; then
            echo "El proceso tar ha comenzado."
            break
        fi
        sleep 1  # Esperar 1 segundo antes de verificar nuevamente
    done
    
    while pgrep -f "tar.*" >/dev/null; do
        sudo kill -SIGUSR1 $(pgrep copia_segur)
        sleep 1
    done
    
    sudo rm -rf "$FS_DIR"
    echo "Test SIGINT finished"
}

#> test_monitoritzar_log

#Test del nice
#> time ./test_cpu.sh

#test comprovar paquet with SIGINT
#> test_SIGINT
#> test_SIGUSR1
