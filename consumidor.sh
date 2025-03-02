#!/bin/bash
# scrip test: sudo kill -SIGUSR $(pgrep consumidor.sh)


informar() {
    echo "=== Informe del proceso ==="
    echo "Tiempo transcurrido: $(($(date +%s) - $TIME)) segundos."
    echo "Uso de CPU: $(ps -o %cpu= -p $(pgrep dd)) %"
    echo "Uso de memoria: $(ps -o %mem= -p $(pgrep dd)) %"
}

acabar(){
    echo "Proceso Finalizado"
    sudo pkill dd
    exit 0
}

seguridad(){
    sudo pkill dd
    exit 0
}


trap informar SIGUSR1
trap acabar SIGUSR2
trap seguridad SIGINT
TIME=$(date +%s)
echo "Script consumidor iniciado. PID: $$"

while true; do
    # Consumir CPU (cálculo intensivo)
    dd if=/dev/zero of=/dev/null &  # Uso intensivo de CPU
    PID=$!
    wait $PID
done