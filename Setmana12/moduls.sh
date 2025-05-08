#!/bin/bash

echo "Verifiación de los modulos..."
sudo lsmod

echo "Montaje de la imagen..."
sudo mount -o loop memtest86-usb.img /mnt

echo "Revisar montaje..."
lsmod | grep -E 'loop|fat|vfat|ext|ntfs|iso'

echo "Ver modulos de uso para el montaje..."
cat /proc/mounts | grep '/mnt'



















