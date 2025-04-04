#!/bin/bash

# Creación del gupo techsoft
if ! getent group techsoft >/dev/null; then
    sudo groupadd techsoft
fi

USERS=("dev1" "dev2" "dev3")
GROUP=techsoft

# Creación de la carpeta del grupo junto con sus permisos
sudo mkdir -p /home/techsoft
sudo chgrp techsoft /home/techsoft
sudo chmod 775 /home/techsoft

# Crear entorno para cada usuario
for usuario in "${USERS[@]}";do
        if ! getent group $GROUP | grep -q $usuario;then
                # Crear usuarios junto a sus cartpeas
                sudo useradd -m -s /bin/bash -d "/home/$GROUP/$usuario" -G "$GROUP" "$usuario"
	fi
done


# Para guardar programas y scripts, solo el grupo techsoft puede escribir
sudo mkdir -p /home/techsoft/bin
sudo chown :techsoft /home/techsoft/bin
sudo chmod 770 /home/techsoft/bin

# Compartir archivos del grupo techsoft contra protección de borrados (SGID bit)
sudo mkdir -p /home/techsoft/shared
sudo chown :techsoft /home/techsoft/shared
sudo chmod 2770 /home/techsoft/shared

# Creación del archivo fet.log perteneciente al usuario dev1
sudo touch /home/techsoft/fet.log
sudo chown dev1:techsoft /home/techsoft/fet.log
sudo chmod 640 /home/techsoft/fet.log

# Informació
echo ""
getent group "$GROUP"

echo ""
for user in "${USERS[@]}";do
	groups "$user"
done

echo ""
ls -l "/home/$GROUP"

echo ""
if [ -f afegir_fet.c ]; then
	echo "Ejecución afegir_fet.c"
	sudo chmod 744 afegir_fet.c
	sudo gcc afegir_fet.c -o afegir_fet
	
	echo -e "\n -Test con Dev1"
	sudo -u dev1 ./afegir_fet "Mensaje Pruebas"
	sudo cat /home/techsoft/fet.log
	
	echo -e "\n -Test con Dev3"
	sudo -u dev3 ./afegir_fet "Mensaje de Error"
else
	echo "Archivo afegir_fet.c no encontrado en la carpeta actual de ejecución"
fi

