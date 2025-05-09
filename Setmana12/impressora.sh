#!/bin/bash

CONTROL=0

if ! dpkg -l cups | grep "ii"; then
	sudo apt update
	CONTROL=1
	sudo apt install -y cups cups-pdf
fi

echo "[+] Ejecutando servicio cups..."
if sudo systemctl start cups; then
	echo "[+] ¡Servicio cups ejecutandose correctamente!"
else
	echo -e "[-] Error en la ejecución del Servicio\n"
	sudo journalctl -u cups --no-pager -xe
fi

echo "[+] Creando archivo DocumentsPDF para el usuario..."
mkdir -p -m 755 /home/milax/DocumentsPDF

# Configurar cups-pdf para usar ~/DocumentsPDF como salida buscando la linea
# que empieza por Out para sustituirla para que busque siempre el directorio
# del usuario
echo "[+] Configurando cups-pdf..."
sudo sed -i "s|^Out.*|Out \${HOME}/DocumentsPDF|g" /etc/cups/cups-pdf.conf

echo "[+] Agregando impresora PDF..."
sudo lpadmin -p ImpressoraPDF -E -v cups-pdf:/ -m lsb/usr/cups-pdf/CUPS-PDF_opt.ppd

echo "[+] Configurando impresora predeterminada para todos..."
sudo lpadmin -d ImpressoraPDF -o printer-opolicy=default  -u allow:@techsoft

echo "[+] Iniciando impresora..."
sudo lpstat -p









