#!/bin/bash

if [[ $# == 0 ]]; then
    echo "Escribe mas de un parametro"
    echo "$0 <Directorio1> <Directorio2>"
    exit 1
fi


# Check the Backup directory exist
directory="/home/GSX/Backups"                              # Save Path of the directory where we will save all backups
sudo mkdir -p "$directory"                                       # Create directory if does not exist


# Get actual Date to create the name of the new file
Date=$(date +"%Y-%m-%d_%Hh-%Mm-%Ss")
BACKUP_FILE="$directory/backup_$Date.tgz"                   # Name of the new Backup with the date

show_progress(){
    echo "*** Progreso de la copia de seguridad ***" > /dev/tty
    if [[ -n "$BACKUP_FILE" && -f "$BACKUP_FILE" ]]; then
        echo "Tamaño del archivo de backup: $(sudo du -h "$BACKUP_FILE" | cut -f1)" > /dev/tty
    else
        echo "Tamaño del archivo de backup: [Archivo no encontrado]" > /dev/tty
    fi
    echo "Estado actual: Comprimiendo archivos..." > /dev/tty
}


trap show_progress SIGUSR1

echo "Crompressing..."
sudo tar -p --atime-preserve -czf "$BACKUP_FILE" "$@" &            # Compress all the files in the new backup

# Esperar cualquier proceso `tar` en segundo plano
while pgrep -f "tar.*$BACKUP_FILE" >/dev/null; do
    sleep 1
done


if [ $? == 0 ]; then
    echo "SUCCESS: Creation Buckup file"
else 
    echo "ERROR: Error creating Buckup file"
    exit 2
fi
