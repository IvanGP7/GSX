#!/bin/bash

echo "Intalling 'monitoritzar_logs.service' every 5 min..."

sudo cp monitoritzar_logs.service /etc/systemd/system/
sudo cp monitoritzar_logs.timer /etc/systemd/system/

echo "Files Copied Successfuly..."

sudo systemctl daemon-reload
sudo systemctl start monitoritzar_logs.service
sudo systemctl start monitoritzar_logs.timer

echo "**STATUS .SERVICE"
systemctl status monitoritzar_logs.service

echo "**STATUS .TIMER"
systemctl status monitoritzar_logs.timer