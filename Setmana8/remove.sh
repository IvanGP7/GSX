#!/bin/bash

echo "Removing Users & Groups..."

sudo rm -rf /home/techsoft

sudo gpasswd -d dev1 techsoft &> /dev/null
sudo gpasswd -d dev2 techsoft &> /dev/null
sudo gpasswd -d dev3 techsoft &> /dev/null

sudo userdel -r dev1 &> /dev/null
sudo userdel -r dev2 &> /dev/null
sudo userdel -r dev3 &> /dev/null

echo "All Removed"
