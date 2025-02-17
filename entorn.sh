#!/bin/bash

#
# Scritp to create a new directory with root as owner and has milax as group
#
path="/home/GSX"

mkdir -p -m 770 $path
chown root:milax $path
echo "Directory created"

