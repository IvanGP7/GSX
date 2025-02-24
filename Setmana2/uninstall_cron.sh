#!/bin/bash

# Ruta al script de copia de seguridad
SCRIPT_PATH="/home/GSX/copia_seguretat.sh"

# Eliminar la entrada del crontab
crontab -l | grep -v "$SCRIPT_PATH" | crontab -

echo "Entrada en crontab eliminada."