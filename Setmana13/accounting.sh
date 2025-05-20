#!/bin/bash

# Archivo de salida
OUTPUT="accounting.txt"

# Verificar y habilitar accounting
if [ ! -f "/var/log/wtmp" ]; then
    echo "Habilitando accounting..."
    sudo accton /var/log/wtmp || sudo accton on
fi

# Registrar comandos de ejemplo
whoami >> "$OUTPUT"
pwd >> "$OUTPUT"
ls -l >> "$OUTPUT"
date >> "$OUTPUT"

# Obtener datos de last y lastcomm
echo "=== Último inicio de sesión ===" >> "$OUTPUT"
last "$USER" | head -n 1 >> "$OUTPUT"

echo "=== Último comando ejecutado ===" >> "$OUTPUT"
lastcomm "$USER" | tail -n 1 >> "$OUTPUT"

echo "Accounting completado. Resultados guardados en $OUTPUT."
