#!/bin/bash

echo "Unintalling 'monitoritzar_logs.service'"

sudo systemctl stop monitoritzar_logs.timer
sudo systemctl stop monitoritzar_logs.service


echo "**STATUS .SERVICE"
systemctl status monitoritzar_logs.service | cat

echo "**STATUS .TIMER"
systemctl status monitoritzar_logs.service | cat

echo "Files Removed Successfuly..."
sudo rm /etc/systemd/system/monitoritzar_logs.service
sudo rm /etc/systemd/system/monitoritzar_logs.timer
sudo rm /var/log/monitoritzar_logs.log