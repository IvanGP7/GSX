#!/bin/bash


# Check the Backup directory exist
directory="/home/GSX/Backups"                              # Save Path of the directory where we will save all backups
sudo mkdir -p "$directory"                                       # Create directory if does not exist


# Crear archivos grandes para que la compresión tarde ~20s
FS_DIR="/home/milax/fake_fs"
echo "Creating a File System in $FS_DIR..."
sudo mkdir -p "$FS_DIR"
for i in {1..7}; do
    sudo dd if=/dev/urandom of="$FS_DIR/file_$i.bin" bs=100M count=1 status=none
done
echo "Filse System Created!"

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
sudo tar -p --atime-preserve -czf "$BACKUP_FILE" "$FS_DIR" &            # Compress all the files in the new backup

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
sudo rm -rf "$FS_DIR"
