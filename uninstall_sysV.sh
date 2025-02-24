#!/bin/bash

sudo service monitoritzar_logs stop

sudo service monitoritzar_logs status | cat

sudo rm /etc/init.d/monitoritzar_logs
sudo rm -f /var/run/monitoritzar_logs.pid   #El servei no elimina el .pid quan fem el stop

sudo systemctl daemon-reload