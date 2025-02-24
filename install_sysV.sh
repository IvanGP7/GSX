#!/bin/bash

sudo systemctl daemon-reload
sudo touch /var/log/monitoritzar_logs.log

sudo cp monitoritzar_logs /etc/init.d/

sudo service monitoritzar_logs start

sudo service monitoritzar_logs status | cat