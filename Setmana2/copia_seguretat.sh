#!/bin/bash

source /home/GSX/copy_directories


# Check the Backup directory exist
directory="/home/GSX/Backups/"                              # Save Path of the directory where we will save all backups
sudo mkdir -p "$directory"                                       # Create directory if does not exist

# Get actual Date to create the name of the new file
Date=$(date +"%Y-%m-%d_%Hh-%Mm-%Ss")
buckup_file="$directory/backup_$Date.tgz"                   # Name of the new Backup with the date

# Show info recursively for all directories

echo "*** Directories Information ***"
for dir in $DIRECTORIES_TO_COPY; do 
    if [ -d "$dir" ]; then                                  # Show all atributes of the files we backup
        find $dir -exec stat --format=$'\nArchivo: %n\nTamaño: %s bytes\nPermisos: %A\nPropietario: %U\nGrupo: %G\nÚltimo acceso: %x\nÚltima modificación: %y\nÚltimo cambio: %z\n' {} \;
    else
        echo "Directory does NOT exist: $dir"
    fi
done

sudo tar -p --atime-preserve -czf "$buckup_file" "${DIRECTORIES_TO_COPY[@]}"            # Compress all the files in the new backup

if [ $? == 0 ]; then
    echo "**SUCCESS: Creation Buckup file"
    echo "**CHECKING CRON LOGS..."
    sudo journalctl -u cron.service | cat
    echo "\n**CHECKING TIMER LOGS..."
    sudo journalctl -u copia_seguretat.timer | cat
    echo "Revisión de logs completada."

else 
    echo "ERROR: Error creating Buckup file"
    exit 2
fi