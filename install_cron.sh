#!/bin/bash

SCRIPT_PATH="/home/GSX/copia_seguretat.sh"

# Añadir la entrada al crontab
(crontab -l 2>/dev/null; echo "0 8 * * * $SCRIPT_PATH") | crontab -

# Verificar que la entrada se ha creado correctamente
if crontab -l | grep "$SCRIPT_PATH"; then
    echo "Prueba exitosa: La entrada en crontab se ha creado correctamente."
else
    echo "Error: La entrada en crontab no se ha creado."
    exit 1
fi