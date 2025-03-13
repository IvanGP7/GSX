#!/bin/bash

# Directori de treball
LOG_FILE="/home/milax/nice_log.txt"
if [[ ! -f $LOG_FILE ]]; then
    echo "" > $LOG_FILE
fi
# Directoris a passar com a paràmetres a copia_seguretat.sh
TARGET_DIRS=("/var" "/usr" "/sys")  # Tots els directoris que has mencionat

# Executa el script de còpia de seguretat amb prioritat baixa
echo "Executant copia_seguretat.sh amb prioritat baixa (nice -n 19) sobre els directoris: ${TARGET_DIRS[*]}..."
sudo nice -n 19 ./copia_seguretat.sh "${TARGET_DIRS[@]}" &

# Espera un moment perquè el procés find s'inicii
sleep 4

echo "Procés find trobat amb PID: $(pgrep find)"

# Observa l'efecte en el consum de CPU amb top i guarda la sortida en un fitxer
echo "Observant l'efecte en el consum de CPU amb top..."
sudo top -b -n 1 | grep "find" >> "$LOG_FILE"
sleep 5

# Augmenta la prioritat del procés find amb renice
echo "Augmentant la prioritat del procés find amb renice..."
sudo renice -n -20 -p "$(pgrep copia_seguretat)"
sudo renice -n -20 -p "$(pgrep find)"

# Observa l'efecte en el consum de CPU amb top després de renice i guarda la sortida en el fitxer
echo "Observant l'efecte en el consum de CPU després de renice..."
sudo top -b -n 1 | grep "find" >> "$LOG_FILE"
sleep 5

# Finalitza l'script
echo "Test finalitzat. Resultats guardats a $LOG_FILE"
sudo pkill copia_seguretat
cat $LOG_FILE
sudo mv $LOG_FILE "/home/GSX/nice_log.txt"
