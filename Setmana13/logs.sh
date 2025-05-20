#!/bin/bash

# Archivo de salida
OUTPUT="logs.txt"

# Simular intentos fallidos (opcional, descomentar si es necesario)
# sudo login usuario_inexistente  # Usuario no válido
# sudo login root                 # Contraseña incorrecta

# Buscar intentos fallidos en los últimos 10 minutos
echo "Buscando intentos de login fallidos..." > "$OUTPUT"
grep -i "failed" /var/log/auth.log | grep "$(date -d '10 minutes ago' +'%b %d %H:%M')" >> "$OUTPUT"

# Contar intentos con usuario inválido
INVALID_COUNT=$(grep -c "invalid user" /var/log/auth.log)
echo "Número total de intentos con usuario inválido: $INVALID_COUNT" >> "$OUTPUT"

echo "Análisis de logs completado. Resultados guardados en $OUTPUT."
