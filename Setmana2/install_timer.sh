#!/bin/bash

# Copiar los archivos de servicio y timer a systemd
sudo cp copia_seguretat.service /etc/systemd/system/
sudo cp copia_seguretat.timer /etc/systemd/system/

# Recargar systemd para reconocer los nuevos archivos
sudo systemctl daemon-reload

# Activar y arrancar el timer
sudo systemctl enable copia_seguretat.timer
sudo systemctl start copia_seguretat.timer

# Verificar que el timer está activo y programado
if systemctl is-active --quiet copia_seguretat.timer; then
    sudo systemctl status copia_seguretat.service | cat
    sudo systemctl status copia_seguretat.timer | cat
    echo "Prueba exitosa: El timer de systemd está activo y programado."
else
    echo "Error: El timer de systemd no está activo."
    exit 1
fi