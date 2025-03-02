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
test_consumidor(){
    # Ruta del archivo de servicio en /home/GSX/
    SERVICE_SOURCE="/home/GSX/consumidor.service"

    # Ruta del archivo de servicio en /etc/systemd/system/
    SERVICE_DEST="/etc/systemd/system/consumidor.service"

    # Archivo de log para guardar la salida del servicio
    LOG_FILE="/home/milax/consumidor.log"

    # Verificar si el archivo de servicio existe
    if [[ ! -f "$SERVICE_SOURCE" ]]; then
        echo "Error: El archivo de servicio $SERVICE_SOURCE no existe."
        exit 1
    fi

    # Verificar si el servicio está activo
    if systemctl is-active --quiet consumidor.service; then
        echo "El servicio está activo. Apagándolo..."
        sudo systemctl stop consumidor.service
    fi

    # Copiar el archivo de servicio a /etc/systemd/system/
    echo "Copiando el archivo de servicio a $SERVICE_DEST..."
    sudo cp "$SERVICE_SOURCE" "$SERVICE_DEST"

    # Recargar systemd
    echo "Recargando systemd..."
    sudo systemctl daemon-reload

    # Habilitar el servicio
    echo "Habilitando el servicio..."
    sudo systemctl enable consumidor.service

    # Iniciar el servicio y redirigir la salida al archivo de log
    echo "Iniciando el servicio y guardando la salida en $LOG_FILE..."
    sudo systemctl start consumidor.service
    sudo journalctl -u consumidor.service -f > "$LOG_FILE" &

    # Mostrar la salida del log en tiempo real
    tail -f "$LOG_FILE" &

    # Esperar a que el servicio esté en ejecución
    sleep 2

    # Obtener el PID del proceso consumidor.sh
    CONSUMIDOR_PID=$(pgrep consumidor.sh)

    if [[ -z "$CONSUMIDOR_PID" ]]; then
        echo "Error: No se pudo obtener el PID del proceso consumidor.sh."
        exit 1
    fi

    echo "El servicio está en ejecución. PID del proceso consumidor.sh: $CONSUMIDOR_PID"
    sleep 3
    echo "Enviando SIGUSR1 al proceso $CONSUMIDOR_PID..."
    sudo kill -SIGUSR1 $(pgrep consumidor)
    sleep 4
    echo "Enviando SIGUSR2 al proceso $CONSUMIDOR_PID..."
    sudo kill -SIGUSR2 $(pgrep consumidor)
    sleep 3

    sudo systemctl stop consumidor.service
    sleep 3
}
test_monitoritzar_log

#Test del nice
time ./test_cpu.sh

#test comprovar paquet with SIGINT
test_SIGINT
test_SIGUSR1

test_consumidor
