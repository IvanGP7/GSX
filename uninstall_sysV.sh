#!/bin/bash

sudo service monitoritzar_logs stop

sudo service monitoritzar_logs status | cat

sudo rm /etc/init.d/monitoritzar_logs

sudo systemctl daemon-reload