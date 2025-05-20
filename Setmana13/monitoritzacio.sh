#!/bin/bash

# Archivo de salida
OUTPUT="monitoritzacio.txt"

# Iniciar vmstat en segundo plano
echo "Iniciando vmstat durante 5 minutos..."
sudo vmstat 1 300 > "$OUTPUT" &

# Esperar 10 segundos para que vmstat se estabilice
sleep 10

# Ejecutar stress para generar carga (CPU y E/S)
echo "Generando carga con stress durante 1 minuto..."
stress --cpu 2 --io 1 --timeout 60s

# Esperar a que vmstat termine
wait

sudo echo "Monitorización completada. Resultados guardados en $OUTPUT."
