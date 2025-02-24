#!/bin/bash

sudo systemctl daemon-reload
sudo touch /var/log/monitoritzar_logs.log

sudo cp monitoritzar_logs /etc/init.d/

sudo rm -f /var/run/monitoritzar_logs.pid
sudo service monitoritzar_logs start

sudo service monitoritzar_logs status | cat