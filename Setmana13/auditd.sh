#!/bin/bash

# Archivo de salida
OUTPUT="auditd.txt"

# Verificar e iniciar auditd
if ! systemctl is-active --quiet auditd; then
    echo "Iniciando auditd..."
    sudo systemctl start auditd
fi

# Crear regla para /etc/shadow
echo "Configurando auditoría para /etc/shadow..." > "$OUTPUT"
sudo auditctl -w /etc/shadow -p w >> "$OUTPUT"

# Simular eventos (cambio de contraseña y login fallido)
echo "Simulando eventos de auditoría..." >> "$OUTPUT"
sudo passwd dev1  # Cambio de contraseña válido


# Buscar eventos recientes
echo "=== Eventos de auditoría ===" >> "$OUTPUT"
sudo ausearch -f /etc/shadow -ts recent -i >> "$OUTPUT"

# Extraer el tipo de operación principal
PRIMARY_OP=$(sudo ausearch -f /etc/shadow -ts recent -i | grep -o "op=[^ ]*" | head -n 1)
echo "Operación principal detectada: $PRIMARY_OP" >> "$OUTPUT"

# Eliminar regla de auditoría
sudo auditctl -D >> "$OUTPUT"

echo "Auditoría completada. Resultados guardados en $OUTPUT."
