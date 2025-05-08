#!/bin/bash

FICHERO="/var/swap"

#Limpieza
if [ -f "/var/swap" ]; then
       sudo swapoff /var/swap
       sudo sed -i '/\/var\/swap/d' /etc/fstab
       sudo rm /var/swap
fi


# Cramos un fichero swap de 16 bloques por 4096k(4 MB) con un total de 64 MB de fichero
echo "Creando fichero Swap de 64MB en ${FICHERO} ..."
sudo dd if=/dev/zero of=${FICHERO} bs=4096k count=16

# Hay que darle permisos de lectura y escritura
echo "Configurando permisos..."
sudo chmod 600 ${FICHERO}

#Formatear área swap
echo "Formateando como swap..."
sudo mkswap ${FICHERO} 

#Activar el swap
sudo swapon ${FICHERO}

#Hacer el swap persistente
if ! grep -q "${FICHERO}" /etc/fstab; then
	echo "${FICHERO} none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
	echo "Entrada añadida a /etc/fstab"
else
	echo " El fichero swap ya estaba en /etc/fstab"
fi

# Verificar
echo "Verificación"
echo -e "-------\n"
sudo swapon --show

echo -e "-------\n"
free -h

echo -e "-------\n"
grep "${FICHERO}" /etc/fstab

echo -e "-------\n"
