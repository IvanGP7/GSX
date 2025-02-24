#!/bin/bash

# Detener y desactivar el temporizador
sudo systemctl stop copia_seguretat.timer
sudo systemctl disable copia_seguretat.timer

# Eliminar los archivos de servicio y temporizador
sudo rm /etc/systemd/system/copia_seguretat.service
sudo rm /etc/systemd/system/copia_seguretat.timer

# Recargar systemd
sudo systemctl daemon-reload

echo "Servicio y temporizador de systemd eliminados."