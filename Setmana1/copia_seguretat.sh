#!/bin/bash


# Check if we recive some param
if [ $# == 0 ]; then
    echo "You didn't write any Param"
    echo "Try: $0 <Directory1> <Directory2>"
    exit 1
fi

# Check the Backup directory exist
directory="/home/GSX/Backups/"                              # Save Path of the directory where we will save all backups
mkdir -p "$directory"                                       # Create directory if does not exist

# Get actual Date to create the name of the new file
Date=$(date +"%Y-%m-%d_%Hh-%Mm-%Ss")
buckup_file="$directory/backup_$Date.tgz"                   # Name of the new Backup with the date

# Show info recursively for all directories

echo "*** Directories Information ***"
for dir in $@; do 
    if [ -d "$dir" ]; then                                  # Show all atributes of the files we backup
        find $dir -exec stat --format=$'\nArchivo: %n\nTamaño: %s bytes\nPermisos: %A\nPropietario: %U\nGrupo: %G\nÚltimo acceso: %x\nÚltima modificación: %y\nÚltimo cambio: %z\n' {} \;
    else
        echo "Directory does NOT exist: $dir"
    fi
done

tar -p --atime-preserve -czf "$buckup_file" "$@"            # Compress all the files in the new backup

if [ $? == 0 ]; then
    echo "SUCCESS: Creation Buckup file"
else 
    echo "ERROR: Error creating Buckup file"
    exit 2
fi